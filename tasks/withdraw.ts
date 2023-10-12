import { task, types } from "hardhat/config"
import { HardhatRuntimeEnvironment } from "hardhat/types"

task("withdraw", "Withdraws the locked funds in the Escrow after it has expired")
    .addParam("contract", "Address of the Escrow contract", undefined, types.string, false)
    .setAction(async ({ contract }, hre: HardhatRuntimeEnvironment) => {
        const blockConfirmations = (await hre.getChainId()) === "31337" ? 1 : 3
        const [grantor] = await hre.ethers.getSigners()
        const escrowFactory = await hre.ethers.getContractFactory("ERC20Escrow")
        const escrow = new hre.ethers.Contract(contract, escrowFactory.interface, grantor)
        const weth = await hre.ethers.getContract("WETH9")
        const grantorWethBalanceBeforeWithdraw = await weth.getFunction("balanceOf").staticCallResult(grantor.address)

        console.log("\n", "\t", `📲 Withdrawing tokens from the contract`)
        console.log(
            "\t",
            `📲 Grantor token balance before withdraw: ${hre.ethers.formatUnits(
                hre.ethers.toBigInt(grantorWethBalanceBeforeWithdraw[0]),
                "ether",
            )} WETH`,
        )

        const withdrawTx = await escrow.getFunction("withdraw").send()

        console.log("\t", `⏳ Waiting for ${blockConfirmations} block confirmations, please wait...`)

        await withdrawTx.wait(blockConfirmations)

        console.log("\t", `✅ Funds withdrew`)

        const grantorWethBalanceAfterWithdraw = await weth.getFunction("balanceOf").staticCallResult(grantor.address)

        console.log(
            "\t",
            `📲 Grantor token balance after withdraw: ${hre.ethers.formatUnits(
                hre.ethers.toBigInt(grantorWethBalanceAfterWithdraw[0]),
                "ether",
            )} WETH`,
            "\n",
        )
    })
