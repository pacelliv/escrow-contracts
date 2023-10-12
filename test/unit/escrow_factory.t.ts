import { assert, expect } from "chai"
import { ethers, network, deployments } from "hardhat"
import { EscrowFactory, WETH9 } from "../../typechain-types"
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { ZeroAddress, parseEther, encodeBytes32String, ContractFactory, MaxUint256 } from "ethers"

const developmentChains = ["hardhat", "localhost"]

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Escrow Factory Unit Tests", () => {
          let nativeEscrow: ContractFactory
          let erc20Escrow: ContractFactory
          let escrowFactory: EscrowFactory
          let factoryAddress: string
          let weth9: WETH9
          let wethAddress: string
          let accounts: SignerWithAddress[]
          let grantor: SignerWithAddress
          let grantee: SignerWithAddress
          let arbiter: SignerWithAddress
          let arbiterFee: bigint
          let payment: bigint
          let duration: bigint
          let salt = encodeBytes32String("SALT")

          beforeEach(async () => {
              accounts = await ethers.getSigners()
              await deployments.fixture(["mocks", "factory"])
              weth9 = await ethers.getContract("WETH9")
              escrowFactory = await ethers.getContract("EscrowFactory")
              wethAddress = await weth9.getAddress()
              factoryAddress = await escrowFactory.getAddress()
              grantor = accounts[0]
              grantee = accounts[1]
              arbiter = accounts[2]
              arbiterFee = BigInt(10)
              payment = parseEther("1")
              duration = BigInt(30000)
              nativeEscrow = await ethers.getContractFactory("NativeEscrow")
              erc20Escrow = await ethers.getContractFactory("ERC20Escrow")

              await weth9.connect(grantor).deposit({ value: parseEther("1") }) // deposit ETH to mint WETH
          })

          describe("factory", () => {
              it("deploy the factory", async () => {
                  assert.notEqual(factoryAddress, ZeroAddress)
              })

              it("deploy mock weth", async () => {
                  assert.notEqual(wethAddress, ZeroAddress)
              })

              it("creates ERC20Escrow", async () => {
                  await weth9.connect(grantor).approve(factoryAddress, parseEther("1")) // approve the factory as spender
                  const computedAddress = await escrowFactory
                      .connect(grantor)
                      .computeERC20EscrowAddress(
                          grantor.address,
                          grantee.address,
                          arbiter.address,
                          wethAddress,
                          arbiterFee,
                          payment,
                          salt,
                          duration,
                          erc20Escrow.bytecode,
                      )

                  const newEscrowTxResponse = await escrowFactory
                      .connect(grantor)
                      .createERC20Escrow(
                          grantee.address,
                          arbiter.address,
                          wethAddress,
                          arbiterFee,
                          payment,
                          salt,
                          duration,
                      )
                  await newEscrowTxResponse.wait()
                  assert.notEqual(computedAddress, ZeroAddress)
              })

              it("creates NativeEscrow", async () => {
                  const computedAddress = await escrowFactory
                      .connect(grantor)
                      .computeNativeEscrowAddress(
                          grantor.address,
                          grantee.address,
                          arbiter.address,
                          arbiterFee,
                          payment,
                          salt,
                          duration,
                          nativeEscrow.bytecode,
                      )
                  const newEscrowTxResponse = await escrowFactory
                      .connect(grantor)
                      .createNativeEscrow(grantee.address, arbiter.address, arbiterFee, payment, salt, duration, {
                          value: payment,
                      })
                  const newEscrowTxReceipt = await newEscrowTxResponse.wait()
                  const nativeEscrowAddress = "0x" + newEscrowTxReceipt?.logs[0].topics[1].slice(-40)
                  assert.equal(nativeEscrowAddress, computedAddress.toLowerCase())
              })

              it("emit event after create a NativeEscrow", async () => {
                  const computedAddress = await escrowFactory
                      .connect(grantor)
                      .computeNativeEscrowAddress(
                          grantor.address,
                          grantee.address,
                          arbiter.address,
                          arbiterFee,
                          payment,
                          salt,
                          duration,
                          nativeEscrow.bytecode,
                      )
                  await expect(
                      escrowFactory
                          .connect(grantor)
                          .createNativeEscrow(grantee.address, arbiter.address, arbiterFee, payment, salt, duration, {
                              value: payment,
                          }),
                  )
                      .to.emit(escrowFactory, "NewNativeEscrow")
                      .withArgs(
                          computedAddress,
                          grantor.address,
                          grantee.address,
                          arbiter.address,
                          arbiterFee,
                          payment,
                          duration,
                      )
              })

              it("emit event after creating a ERC20Escrow", async () => {
                  await weth9.connect(grantor).approve(factoryAddress, parseEther("1"))

                  const computedAddress = await escrowFactory
                      .connect(grantor)
                      .computeERC20EscrowAddress(
                          grantor.address,
                          grantee.address,
                          arbiter.address,
                          wethAddress,
                          arbiterFee,
                          payment,
                          salt,
                          duration,
                          erc20Escrow.bytecode,
                      )

                  await expect(
                      escrowFactory.createERC20Escrow(
                          grantee.address,
                          arbiter.address,
                          wethAddress,
                          arbiterFee,
                          payment,
                          salt,
                          duration,
                      ),
                  )
                      .to.emit(escrowFactory, "NewERC20Escrow")
                      .withArgs(
                          computedAddress,
                          grantor.address,
                          grantee.address,
                          arbiter.address,
                          wethAddress,
                          arbiterFee,
                          payment,
                          duration,
                      )
              })

              it("revert if msg.value and payment are not equal", async () => {
                  await expect(
                      escrowFactory
                          .connect(grantor)
                          .createNativeEscrow(grantee.address, arbiter.address, arbiterFee, payment, salt, duration),
                  ).to.be.revertedWithCustomError(escrowFactory, "EscrowFactory__ValuesMismatch")
              })

              it("revert if token transfer fails", async () => {
                  await expect(
                      escrowFactory
                          .connect(grantor)
                          .createERC20Escrow(
                              grantee.address,
                              arbiter.address,
                              wethAddress,
                              arbiterFee,
                              payment,
                              salt,
                              duration,
                          ),
                  ).to.be.reverted
              })

              it("revert if re-deploy with same salt", async () => {
                  await weth9.connect(grantor).approve(factoryAddress, MaxUint256) // approve the factory as spender
                  await escrowFactory
                      .connect(grantor)
                      .createERC20Escrow(
                          grantee.address,
                          arbiter.address,
                          wethAddress,
                          arbiterFee,
                          payment,
                          salt,
                          duration,
                      )
                  await expect(
                      escrowFactory
                          .connect(grantor)
                          .createERC20Escrow(
                              grantee.address,
                              arbiter.address,
                              wethAddress,
                              arbiterFee,
                              payment,
                              salt,
                              duration,
                          ),
                  ).to.be.reverted
              })
          })
      })
