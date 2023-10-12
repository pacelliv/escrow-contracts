import { deployments, network, ethers } from "hardhat"
import { EscrowFactory, WETH9 } from "../../typechain-types"
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { ContractFactory, MaxUint256, ZeroAddress, parseEther, Contract, AddressLike } from "ethers"
import { encodeBytes32String } from "ethers"
import { assert, expect } from "chai"

const developmentChains = ["hardhat", "localhost"]

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Escrow Unit Tests", () => {
          let escrowBytecode: ContractFactory
          let escrow: Contract
          let escrowFactory: EscrowFactory
          let weth9: WETH9
          let accounts: SignerWithAddress[]
          let grantor: SignerWithAddress
          let grantee: SignerWithAddress
          let arbiter: SignerWithAddress
          let escrowAddress: string | undefined
          let escrowFactoryAddress: string
          let arbiterFee: bigint
          let payment: bigint
          let weth9Address: string
          let salt = encodeBytes32String("SALT")
          let duration: bigint
          let state = {
              CREATED: 0,
              CONFIRMED: 1,
              DISPUTED: 2,
              RESOLVED: 3,
          }

          beforeEach(async () => {
              await deployments.fixture(["factory", "mocks"])
              accounts = await ethers.getSigners()
              weth9 = await ethers.getContract("WETH9")
              escrowFactory = await ethers.getContract("EscrowFactory")
              grantor = accounts[0]
              grantee = accounts[1]
              arbiter = accounts[2]
              escrowFactoryAddress = await escrowFactory.getAddress()
              weth9Address = await weth9.getAddress()
              arbiterFee = BigInt(10)
              payment = parseEther("1")
              duration = BigInt(30000)
              escrowBytecode = await ethers.getContractFactory("ERC20Escrow")

              await weth9.connect(grantor).deposit({ value: parseEther("2") })
              await weth9.connect(grantor).approve(escrowFactoryAddress, MaxUint256)

              const createEscrowTxResponse = await escrowFactory
                  .connect(grantor)
                  .createERC20Escrow(
                      grantee.address,
                      arbiter.address,
                      weth9Address,
                      arbiterFee,
                      payment,
                      salt,
                      duration,
                  )
              const txReceipt = await createEscrowTxResponse.wait()
              escrowAddress = "0x" + txReceipt?.logs[0].topics[2].slice(-40)
              escrow = new ethers.Contract(escrowAddress, escrowBytecode.interface, grantor)
          })

          describe("createEscrow", () => {
              it("deploys the escrow correctly", async () => {
                  const grantorFromContract = await escrow.getGrantor()
                  const granteeFromContract = await escrow.getGrantee()
                  const arbiterFromContract = await escrow.getArbiter()
                  const tokenFromContract = await escrow.getToken()
                  const arbiterFeeFromContract = await escrow.getArbiterFee()
                  const paymentFromContract = await escrow.getPayment()
                  const maxFeeFromContract = await escrow.getMaxFee()
                  const stateFromContract = await escrow.getState()
                  const escrowWethBalance = await weth9.balanceOf(escrowAddress ? (escrowAddress as AddressLike) : "")
                  assert.strictEqual(grantorFromContract, grantor.address, "grantors addresses does not match")
                  assert.strictEqual(granteeFromContract, grantee.address, "grantees addresses does not match")
                  assert.strictEqual(arbiterFromContract, arbiter.address, "arbiters addresses does not match")
                  assert.strictEqual(tokenFromContract, weth9Address, "tokens addresses does not match")
                  assert.strictEqual(arbiterFeeFromContract, arbiterFee, "arbiters fees does not match")
                  assert.strictEqual(paymentFromContract, payment, "payments values does not match")
                  assert.strictEqual(Number(maxFeeFromContract), 12, "max fee values does not match")
                  assert.strictEqual(Number(stateFromContract), state.CREATED, "escrow contract in incorrect state")
                  assert.strictEqual(escrowWethBalance, payment, "escrow contract balance not updated")
              })
          })

          describe("confirms receipt", () => {
              it("grantor confirm the receipt and transfer payment to the grantee", async () => {
                  const confirmReceiptTx = await escrow.confirmReceipt()
                  await confirmReceiptTx.wait()

                  const escrowWethBalance = await weth9.balanceOf(escrowAddress ? (escrowAddress as AddressLike) : "")
                  const granteeWETHBalance = await weth9.balanceOf(grantee.address)
                  const escrowState = await escrow.getState()
                  assert.strictEqual(
                      Number(escrowState),
                      state.CONFIRMED,
                      "escrow contract is wrong state after receipt confirmed",
                  )
                  assert.strictEqual(escrowWethBalance, BigInt(0), "escrow contract still hold tokens")
                  assert.strictEqual(granteeWETHBalance, payment, "payment not fully transferred to grantee")
              })

              it("emit event after grantor confirms the receipt", async () => {
                  await expect(escrow.confirmReceipt())
                      .to.emit(escrow, "ReceiptConfirmed")
                      .withArgs(grantor.address, grantee.address, payment)
              })
          })

          describe("withdraw", () => {
              it("allows the grantor to withdraw the payment after the escrow expired", async () => {
                  await network.provider.request({ method: "evm_increaseTime", params: [30001] })
                  await network.provider.request({ method: "evm_mine", params: [] })
                  const withdrawTx = await escrow.withdraw()
                  await withdrawTx.wait()
                  const grantorWethBalance = await weth9.balanceOf(grantor.address)
                  const escrowWethBalance = await weth9.balanceOf(escrowAddress ? (escrowAddress as AddressLike) : "")
                  const escrowState = await escrow.getState()
                  assert.strictEqual(grantorWethBalance, parseEther("2"), "missmatch balance after withdraw")
                  assert.strictEqual(escrowWethBalance.toString(), "0", "missmatch balance after withdraw")
                  assert.strictEqual(Number(escrowState), state.RESOLVED, "wrong state after withdraw")
              })
          })

          describe("initiate dispute", () => {
              it("grantor can initiate a dispute", async () => {
                  await network.provider.request({ method: "evm_increaseTime", params: [15000] })
                  await network.provider.request({ method: "evm_mine", params: [] })
                  const startDisputeTx = await escrow.startDispute()
                  await startDisputeTx.wait()

                  const escrowState = await escrow.getState()
                  assert.strictEqual(
                      Number(escrowState),
                      state.DISPUTED,
                      "escrow contract is wrong state after dispute initiated",
                  )
              })

              it("grantee can initiate a dispute", async () => {
                  await network.provider.request({ method: "evm_increaseTime", params: [15000] })
                  await network.provider.request({ method: "evm_mine", params: [] })
                  escrow = new ethers.Contract(escrowAddress ? escrowAddress : "", escrowBytecode.interface, grantee)
                  const startDisputeTx = await escrow.startDispute()
                  await startDisputeTx.wait()

                  const escrowState = await escrow.getState()
                  assert.strictEqual(
                      Number(escrowState),
                      state.DISPUTED,
                      "escrow contract is wrong state after dispute initiated",
                  )
              })
          })

          describe("resolve dispute", () => {
              it("arbiter resolves a dispute", async () => {
                  await network.provider.request({ method: "evm_increaseTime", params: [15000] })
                  await network.provider.request({ method: "evm_mine", params: [] })

                  escrow = new ethers.Contract(escrowAddress ? escrowAddress : "", escrowBytecode.interface, grantee)
                  const startDisputeTx = await escrow.startDispute()
                  await startDisputeTx.wait()

                  assert.strictEqual(Number(await escrow.getState()), state.DISPUTED, "escrow not in DIPUTED")

                  escrow = new ethers.Contract(escrowAddress ? escrowAddress : "", escrowBytecode.interface, arbiter)
                  const resolveDisputeTx = await escrow.resolveDispute(BigInt(50))
                  await resolveDisputeTx.wait()

                  const grantorWethBalance = await weth9.balanceOf(grantor.address)
                  const granteeWethBalance = await weth9.balanceOf(grantee.address)
                  const arbiterWethBalance = await weth9.balanceOf(arbiter.address)
                  const escrowState = await escrow.getState()

                  assert.strictEqual(grantorWethBalance, parseEther("1.45"), "wrong balance after dispute resolved")
                  assert.strictEqual(granteeWethBalance, parseEther("0.45"), "wrong balance after dispute resolved")
                  assert.strictEqual(arbiterWethBalance, parseEther("0.1"), "wrong balance after dispute resolved")
                  assert.strictEqual(Number(escrowState), state.RESOLVED)
              })

              it("emit event after resolving a dispute", async () => {
                  await network.provider.request({ method: "evm_increaseTime", params: [15000] })
                  await network.provider.request({ method: "evm_mine", params: [] })

                  escrow = new ethers.Contract(escrowAddress ? escrowAddress : "", escrowBytecode.interface, grantee)
                  const startDisputeTx = await escrow.startDispute()
                  await startDisputeTx.wait()

                  escrow = new ethers.Contract(escrowAddress ? escrowAddress : "", escrowBytecode.interface, arbiter)
                  await expect(escrow.resolveDispute(BigInt(50)))
                      .to.emit(escrow, "Resolved")
                      .withArgs(
                          arbiter.address,
                          grantor.address,
                          grantee.address,
                          parseEther("0.1"),
                          parseEther("0.45"),
                          parseEther("0.45"),
                      )
              })
          })

          describe("escrow reverts", () => {
              it("reverts if duration is zero", async () => {
                  await expect(
                      escrowFactory
                          .connect(grantor)
                          .createERC20Escrow(
                              grantee.address,
                              arbiter.address,
                              weth9Address,
                              arbiterFee,
                              payment,
                              salt,
                              0,
                          ),
                  ).to.be.revertedWithCustomError(escrow, "Escrow__ZeroDuration")
              })

              it("revert if arbiter fee is zero", async () => {
                  await expect(
                      escrowFactory
                          .connect(grantor)
                          .createERC20Escrow(
                              grantee.address,
                              arbiter.address,
                              weth9Address,
                              0,
                              payment,
                              salt,
                              duration,
                          ),
                  ).to.be.revertedWithCustomError(escrow, "Escrow__ZeroAmount")
              })

              it("reverts if payment is zero", async () => {
                  await expect(
                      escrowFactory
                          .connect(grantor)
                          .createERC20Escrow(
                              grantee.address,
                              arbiter.address,
                              weth9Address,
                              arbiterFee,
                              0,
                              salt,
                              duration,
                          ),
                  ).to.be.revertedWithCustomError(escrow, "Escrow__ZeroAmount")
              })

              it("reverts if grantee is zero address", async () => {
                  await expect(
                      escrowFactory
                          .connect(grantor)
                          .createERC20Escrow(
                              ZeroAddress,
                              arbiter.address,
                              weth9Address,
                              arbiterFee,
                              payment,
                              salt,
                              duration,
                          ),
                  ).to.be.revertedWithCustomError(escrow, "Escrow__AddressZero")
              })

              it("reverts if arbiter is zero address", async () => {
                  await expect(
                      escrowFactory
                          .connect(grantor)
                          .createERC20Escrow(
                              grantee.address,
                              ZeroAddress,
                              weth9Address,
                              arbiterFee,
                              payment,
                              salt,
                              duration,
                          ),
                  ).to.be.revertedWithCustomError(escrow, "Escrow__AddressZero")
              })

              it("reverts if arbiter fee > max fee", async () => {
                  await expect(
                      escrowFactory
                          .connect(grantor)
                          .createERC20Escrow(
                              grantee.address,
                              arbiter.address,
                              weth9Address,
                              parseEther("1"),
                              payment,
                              salt,
                              duration,
                          ),
                  )
                      .to.be.revertedWithCustomError(escrow, "Escrow__FeeExceedMax")
                      .withArgs(parseEther("1"), BigInt(12))
              })

              it("reverts if grantor tries to confirm receipt after escrow expired", async () => {
                  await network.provider.request({ method: "evm_increaseTime", params: [30001] })
                  await network.provider.request({ method: "evm_mine", params: [] })
                  await expect(escrow.confirmReceipt()).to.be.revertedWithCustomError(escrow, "Escrow__EscrowExpired")
              })

              it("only the grantor can confirm the receipt", async () => {
                  // grantee tries to execute confirmReceipt
                  escrow = new ethers.Contract(escrowAddress ? escrowAddress : "", escrowBytecode.interface, grantee)
                  await expect(escrow.confirmReceipt()).to.be.revertedWithCustomError(escrow, "Escrow__Unauthorized")

                  // arbiter tries to execute confirmReceipt
                  escrow = new ethers.Contract(escrowAddress ? escrowAddress : "", escrowBytecode.interface, arbiter)
                  await expect(escrow.confirmReceipt()).to.be.revertedWithCustomError(escrow, "Escrow__Unauthorized")
              })

              it("reverts if arbiter tries to initiate a dispute", async () => {
                  await network.provider.request({ method: "evm_increaseTime", params: [15000] })
                  await network.provider.request({ method: "evm_mine", params: [] })
                  escrow = new ethers.Contract(escrowAddress ? escrowAddress : "", escrowBytecode.interface, arbiter)
                  await expect(escrow.startDispute()).to.be.revertedWithCustomError(escrow, "Escrow__Unauthorized")
              })

              it("reverts if startDispute is called after the escrow expired", async () => {
                  await network.provider.request({ method: "evm_increaseTime", params: [30001] })
                  await network.provider.request({ method: "evm_mine", params: [] })
                  await expect(escrow.startDispute()).to.be.revertedWithCustomError(escrow, "Escrow__EscrowExpired")
              })

              it("reverts if grantor == grantee", async () => {
                  await expect(
                      escrowFactory
                          .connect(grantor)
                          .createERC20Escrow(
                              grantor.address,
                              arbiter.address,
                              weth9Address,
                              arbiterFee,
                              payment,
                              salt,
                              duration,
                          ),
                  ).to.be.revertedWithCustomError(escrow, "Escrow__RepeatedParticipant")
              })

              it("reverts if grantor == arbiter", async () => {
                  await expect(
                      escrowFactory
                          .connect(grantor)
                          .createERC20Escrow(
                              grantee.address,
                              grantor.address,
                              weth9Address,
                              arbiterFee,
                              payment,
                              salt,
                              duration,
                          ),
                  ).to.be.revertedWithCustomError(escrow, "Escrow__RepeatedParticipant")
              })

              it("reverts if grantee = arbiter", async () => {
                  await expect(
                      escrowFactory
                          .connect(grantor)
                          .createERC20Escrow(
                              arbiter.address,
                              arbiter.address,
                              weth9Address,
                              arbiterFee,
                              payment,
                              salt,
                              duration,
                          ),
                  ).to.be.revertedWithCustomError(escrow, "Escrow__RepeatedParticipant")
              })

              it("reverts if resolveDispute is not called by the arbiter", async () => {
                  // revert grantee
                  escrow = new ethers.Contract(escrowAddress ? escrowAddress : "", escrowBytecode.interface, grantee)
                  const startDisputeTxGrantee = await escrow.startDispute()
                  await startDisputeTxGrantee.wait()
                  await expect(escrow.resolveDispute(BigInt(0))).to.be.revertedWithCustomError(
                      escrow,
                      "Escrow__Unauthorized",
                  )

                  // revert grantor
                  escrow = new ethers.Contract(escrowAddress ? escrowAddress : "", escrowBytecode.interface, grantor)
                  await expect(escrow.resolveDispute(BigInt(0))).to.be.revertedWithCustomError(
                      escrow,
                      "Escrow__Unauthorized",
                  )
              })

              it("resolve reverts because escrow is not in disputed state", async () => {
                  escrow = new ethers.Contract(escrowAddress ? escrowAddress : "", escrowBytecode.interface, grantor)
                  await expect(escrow.resolveDispute(BigInt(0)))
                      .to.be.revertedWithCustomError(escrow, "Escrow__InWrongState")
                      .withArgs(2, 0)
              })
          })
      })
