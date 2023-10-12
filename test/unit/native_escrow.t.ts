import { expect, assert } from "chai"
import { network, ethers, deployments } from "hardhat"
import { encodeBytes32String, parseEther, Contract, ZeroAddress } from "ethers"
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { time } from "@nomicfoundation/hardhat-network-helpers"
import { EscrowFactory } from "../../typechain-types"

const developmentChains = ["localhost", "hardhat"]

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("NativeEscrow Unit Tests", () => {
          let escrowFactory: EscrowFactory
          let nativeEscrow: Contract
          let grantor: SignerWithAddress
          let grantee: SignerWithAddress
          let arbiter: SignerWithAddress
          const arbiterFee = BigInt(10)
          const payment = parseEther("1")
          const salt = encodeBytes32String("salt")
          const duration = BigInt(30000)
          const grantorRefund = BigInt(50)
          const state = {
              CREATED: 0,
              CONFIRMED: 1,
              DISPUTED: 2,
              RESOLVED: 3,
          }

          beforeEach(async () => {
              const accounts = await ethers.getSigners()
              grantor = accounts[0]
              grantee = accounts[1]
              arbiter = accounts[2]
              await deployments.fixture(["factory"])
              escrowFactory = await ethers.getContract("EscrowFactory")
              const createNativeEscrowTxResponse = await escrowFactory
                  .connect(grantor)
                  .getFunction("createNativeEscrow")
                  .send(grantee.address, arbiter.address, arbiterFee, payment, salt, duration, { value: payment })
              const createNativeEscrowTxReceipt = await createNativeEscrowTxResponse.wait()
              const nativeEscrowAddress = "0x" + createNativeEscrowTxReceipt?.logs[0].topics[1].slice(-40)
              const nativeEscrowFactory = await ethers.getContractFactory("NativeEscrow")
              nativeEscrow = new ethers.Contract(nativeEscrowAddress, nativeEscrowFactory.interface, grantor)
          })

          describe("NativeEscrow: deployment", () => {
              it("NativeEscrow is deployed correctly", async () => {
                  const timestamp = await time.latest() // get latest timestamp from the network
                  const escrowBalance = await ethers.provider.getBalance(await nativeEscrow.getAddress())
                  const durationFromContract = await nativeEscrow.getFunction("getDuration").staticCall()
                  const grantorFromContract = await nativeEscrow.getFunction("getGrantor").staticCallResult()
                  const granteeFromContract = await nativeEscrow.getFunction("getGrantee").staticCallResult()
                  const arbiterFromContract = await nativeEscrow.getFunction("getArbiter").staticCallResult()
                  const arbiterFeeFromContract = await nativeEscrow.getFunction("getArbiterFee").staticCallResult()
                  const paymentFromContract = await nativeEscrow.getFunction("getPayment").staticCallResult()
                  const nativeEscrowState = await nativeEscrow.getFunction("getState").staticCallResult()
                  assert.strictEqual(escrowBalance, payment, "Escrow deployed without balance")
                  assert.strictEqual(
                      Number(durationFromContract),
                      Number(duration) + timestamp,
                      "duration values does not match",
                  )
                  assert.strictEqual(grantorFromContract[0], grantor.address, "grantor values does not match")
                  assert.strictEqual(granteeFromContract[0], grantee.address, "grantee values does not match")
                  assert.strictEqual(arbiterFromContract[0], arbiter.address, "arbiter values does not match")
                  assert.strictEqual(Number(arbiterFeeFromContract), Number(arbiterFee), "fees values does not match")
                  assert.strictEqual(Number(paymentFromContract), Number(payment), "payments values does not match")
                  assert.strictEqual(Number(nativeEscrowState), state.CREATED, "state does not match")
              })

              describe("NativeEscrow: core functions", () => {
                  it("grantor confirms the receipt", async () => {
                      const initialGranteeBalance = await ethers.provider.getBalance(grantee.address)
                      const confirmReceiptTx = await nativeEscrow.connect(grantor).getFunction("confirmReceipt").send()
                      await confirmReceiptTx.wait()
                      const endingEscrowBalance = await ethers.provider.getBalance(await nativeEscrow.getAddress())
                      const endingGranteeBalance = await ethers.provider.getBalance(grantee.address)
                      const escrowState = await nativeEscrow.getFunction("getState").staticCallResult()
                      assert.strictEqual(Number(endingEscrowBalance), 0)
                      assert.strictEqual(endingGranteeBalance, initialGranteeBalance + payment)
                      assert.strictEqual(Number(escrowState), state.CONFIRMED)
                  })

                  it("grantor withdraw escrowed balance", async () => {
                      const initialGrantorBalance = await ethers.provider.getBalance(grantor.address)
                      await network.provider.request({ method: "evm_increaseTime", params: [30001] })
                      await network.provider.request({ method: "evm_mine", params: [] })
                      const withdrawTx = await nativeEscrow.connect(grantor).getFunction("withdraw").send()
                      const withdrawTxReceipt = await withdrawTx.wait()
                      const escrowState = await nativeEscrow.getFunction("getState").staticCallResult()
                      assert.strictEqual(Number(escrowState), state.RESOLVED)
                      const escrowBalance = await ethers.provider.getBalance(await nativeEscrow.getAddress())
                      assert.strictEqual(Number(escrowBalance), 0)
                      const gasPrice = withdrawTxReceipt?.gasPrice
                      const gasUsed = withdrawTxReceipt?.gasUsed
                      const endingGrantorBalance = await ethers.provider.getBalance(grantor.address)

                      if (gasPrice !== undefined && gasUsed !== undefined) {
                          const gasCost = gasPrice * gasUsed
                          assert.strictEqual(endingGrantorBalance, initialGrantorBalance + payment - gasCost)
                      }
                  })

                  it("allows to starts a dispute", async () => {
                      const startDisputeTx = await nativeEscrow.connect(grantee).getFunction("startDispute").send()
                      await startDisputeTx.wait()
                      const escrowState = await nativeEscrow.getFunction("getState").staticCallResult()
                      assert.strictEqual(Number(escrowState), state.DISPUTED)
                  })

                  it("allows to resolve disputes", async () => {
                      const startDisputeTx = await nativeEscrow.connect(grantee).getFunction("startDispute").send()
                      await startDisputeTx.wait()

                      const escrowStateDisputed = await nativeEscrow.getFunction("getState").staticCallResult()
                      assert.strictEqual(Number(escrowStateDisputed), state.DISPUTED)

                      const initialGrantorBalance = await ethers.provider.getBalance(grantor.address)
                      const initialGranteeBalance = await ethers.provider.getBalance(grantee.address)
                      const initialArbiterBalance = await ethers.provider.getBalance(arbiter.address)

                      const resolveDisputeTx = await nativeEscrow
                          .connect(arbiter)
                          .getFunction("resolveDispute")
                          .send(grantorRefund)
                      const resolveDisputeTxReceipt = await resolveDisputeTx.wait()
                      const endingGrantorBalance = await ethers.provider.getBalance(grantor.address)
                      const endingGranteeBalance = await ethers.provider.getBalance(grantee.address)
                      const endingArbiterBalance = await ethers.provider.getBalance(arbiter.address)
                      const gasUsed = resolveDisputeTxReceipt?.gasUsed
                      const gasPrice = resolveDisputeTxReceipt?.gasPrice
                      const escrowStateResolved = await nativeEscrow.getFunction("getState").staticCallResult()

                      // assertions
                      // escrow contract holds 1 ether
                      // if grantorRefund = 50% and arbiterFee = 10%
                      // - arbiter gets 0.1 ether
                      // - remaingin 0.9 ether is distributed as such: grantee and grantor gets 0.45 ether, respectively
                      assert.strictEqual(endingGrantorBalance, initialGrantorBalance + parseEther("0.45"))
                      assert.strictEqual(endingGranteeBalance, initialGranteeBalance + parseEther("0.45"))
                      if (gasPrice !== undefined && gasUsed !== undefined) {
                          const gasCost = gasPrice * gasUsed
                          assert.strictEqual(endingArbiterBalance, initialArbiterBalance + parseEther("0.1") - gasCost)
                      }

                      assert.strictEqual(Number(escrowStateResolved), state.RESOLVED)
                  })

                  describe("NativeEscrow: events", () => {
                      it("emit event after confirming receipt", async () => {
                          await expect(nativeEscrow.connect(grantor).getFunction("confirmReceipt").send())
                              .to.emit(nativeEscrow, "ReceiptConfirmed")
                              .withArgs(grantor.address, grantee.address, payment)
                      })

                      it("emit event after starting a dispute", async () => {
                          await expect(nativeEscrow.connect(grantee).getFunction("startDispute").send())
                              .to.emit(nativeEscrow, "Dispute")
                              .withArgs(grantee.address)
                      })

                      it("emit event start resolving a dispute", async () => {
                          const startDisputeTx = await nativeEscrow.connect(grantee).getFunction("startDispute").send()
                          await startDisputeTx.wait()
                          await expect(nativeEscrow.connect(arbiter).getFunction("resolveDispute").send(grantorRefund))
                              .to.emit(nativeEscrow, "Resolved")
                              .withArgs(
                                  arbiter.address,
                                  grantor.address,
                                  grantee.address,
                                  parseEther("0.1"),
                                  parseEther("0.45"),
                                  parseEther("0.45"),
                              )
                      })

                      it("emit event after withdrawn escrowed tokens", async () => {
                          await network.provider.request({ method: "evm_increaseTime", params: [30001] })
                          await network.provider.request({ method: "evm_mine", params: [] })
                          await expect(nativeEscrow.connect(grantor).getFunction("withdraw").send())
                              .to.emit(nativeEscrow, "Withdraw")
                              .withArgs(payment)
                      })
                  })

                  describe("NativeEscrow: reverts", () => {
                      it("reverts if duration is zero", async () => {
                          await expect(
                              escrowFactory
                                  .connect(grantor)
                                  .createNativeEscrow(grantee.address, arbiter.address, arbiterFee, payment, salt, 0, {
                                      value: payment,
                                  }),
                          ).to.be.revertedWithCustomError(nativeEscrow, "Escrow__ZeroDuration")
                      })

                      it("revert if arbiter fee is zero", async () => {
                          await expect(
                              escrowFactory
                                  .connect(grantor)
                                  .createNativeEscrow(grantee.address, arbiter.address, 0, payment, salt, duration, {
                                      value: payment,
                                  }),
                          ).to.be.revertedWithCustomError(nativeEscrow, "Escrow__ZeroAmount")
                      })

                      it("reverts if grantee is zero address", async () => {
                          await expect(
                              escrowFactory
                                  .connect(grantor)
                                  .createNativeEscrow(
                                      ZeroAddress,
                                      arbiter.address,
                                      arbiterFee,
                                      payment,
                                      salt,
                                      duration,
                                      { value: payment },
                                  ),
                          ).to.be.revertedWithCustomError(nativeEscrow, "Escrow__AddressZero")
                      })

                      it("reverts if arbiter is zero address", async () => {
                          await expect(
                              escrowFactory
                                  .connect(grantor)
                                  .createNativeEscrow(
                                      grantee.address,
                                      ZeroAddress,
                                      arbiterFee,
                                      payment,
                                      salt,
                                      duration,
                                      { value: payment },
                                  ),
                          ).to.be.revertedWithCustomError(nativeEscrow, "Escrow__AddressZero")
                      })

                      it("reverts if arbiter fee > max fee", async () => {
                          await expect(
                              escrowFactory
                                  .connect(grantor)
                                  .createNativeEscrow(
                                      grantee.address,
                                      arbiter.address,
                                      parseEther("1"),
                                      payment,
                                      salt,
                                      duration,
                                      { value: payment },
                                  ),
                          )
                              .to.be.revertedWithCustomError(nativeEscrow, "Escrow__FeeExceedMax")
                              .withArgs(parseEther("1"), BigInt(12))
                      })

                      it("reverts if grantor tries to confirm receipt after escrow expired", async () => {
                          await network.provider.request({ method: "evm_increaseTime", params: [30001] })
                          await network.provider.request({ method: "evm_mine", params: [] })
                          await expect(nativeEscrow.confirmReceipt()).to.be.revertedWithCustomError(
                              nativeEscrow,
                              "Escrow__EscrowExpired",
                          )
                      })

                      it("only the grantor can confirm the receipt", async () => {
                          // grantee tries to execute confirmReceipt
                          await expect(
                              nativeEscrow.connect(grantee).getFunction("confirmReceipt").send(),
                          ).to.be.revertedWithCustomError(nativeEscrow, "Escrow__Unauthorized")

                          // arbiter tries to execute confirmReceipt
                          await expect(
                              nativeEscrow.connect(arbiter).getFunction("confirmReceipt").send(),
                          ).to.be.revertedWithCustomError(nativeEscrow, "Escrow__Unauthorized")
                      })

                      it("reverts if arbiter tries to initiate a dispute", async () => {
                          await network.provider.request({ method: "evm_increaseTime", params: [15000] })
                          await network.provider.request({ method: "evm_mine", params: [] })
                          await expect(
                              nativeEscrow.connect(arbiter).getFunction("startDispute").send(),
                          ).to.be.revertedWithCustomError(nativeEscrow, "Escrow__Unauthorized")
                      })

                      it("reverts if startDispute is called after the escrow expired", async () => {
                          await network.provider.request({ method: "evm_increaseTime", params: [30001] })
                          await network.provider.request({ method: "evm_mine", params: [] })
                          await expect(
                              nativeEscrow.connect(grantee).getFunction("startDispute").send(),
                          ).to.be.revertedWithCustomError(nativeEscrow, "Escrow__EscrowExpired")
                      })

                      it("reverts if grantor == grantee", async () => {
                          await expect(
                              escrowFactory
                                  .connect(grantor)
                                  .createNativeEscrow(
                                      grantor.address,
                                      arbiter.address,
                                      arbiterFee,
                                      payment,
                                      salt,
                                      duration,
                                      { value: payment },
                                  ),
                          ).to.be.revertedWithCustomError(nativeEscrow, "Escrow__RepeatedParticipant")
                      })

                      it("reverts if grantor == arbiter", async () => {
                          await expect(
                              escrowFactory
                                  .connect(grantor)
                                  .createNativeEscrow(
                                      grantee.address,
                                      grantor.address,
                                      arbiterFee,
                                      payment,
                                      salt,
                                      duration,
                                      { value: payment },
                                  ),
                          ).to.be.revertedWithCustomError(nativeEscrow, "Escrow__RepeatedParticipant")
                      })

                      it("reverts if grantee = arbiter", async () => {
                          await expect(
                              escrowFactory
                                  .connect(grantor)
                                  .createNativeEscrow(
                                      arbiter.address,
                                      arbiter.address,
                                      arbiterFee,
                                      payment,
                                      salt,
                                      duration,
                                      { value: payment },
                                  ),
                          ).to.be.revertedWithCustomError(nativeEscrow, "Escrow__RepeatedParticipant")
                      })

                      it("reverts if resolveDispute is not called by the arbiter", async () => {
                          // revert grantee
                          const startDisputeTxGrantee = await nativeEscrow
                              .connect(grantee)
                              .getFunction("startDispute")
                              .send()
                          await startDisputeTxGrantee.wait()
                          // grantee tries to resolve dispute by refundin zero to the grantor
                          await expect(
                              nativeEscrow.connect(grantee).getFunction("resolveDispute").send(BigInt(0)),
                          ).to.be.revertedWithCustomError(nativeEscrow, "Escrow__Unauthorized")

                          // revert grantor
                          // grantor tries to resolve dispute by recovering the majority of the escrowed funds
                          await expect(
                              nativeEscrow.connect(grantor).getFunction("resolveDispute").send(BigInt(100)),
                          ).to.be.revertedWithCustomError(nativeEscrow, "Escrow__Unauthorized")
                      })

                      it("resolve reverts because escrow is not in disputed state", async () => {
                          await expect(nativeEscrow.connect(grantee).getFunction("resolveDispute").send(BigInt(0)))
                              .to.be.revertedWithCustomError(nativeEscrow.connect(grantee), "Escrow__InWrongState")
                              .withArgs(2, 0)
                      })
                  })
              })
          })
      })
