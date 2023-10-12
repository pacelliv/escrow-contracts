import { task, types } from "hardhat/config"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import "dotenv/config"

task("confirm-receipt", "Confirm the receipt unlocking the payment to the grantee")
    .addParam("contract", "Address of the escrow", undefined, types.string, false)
    .setAction(async ({ contract }, hre: HardhatRuntimeEnvironment) => {
        const blockConfirmations = (await hre.getChainId()) === "31337" ? 1 : 3
        const [grantor, grantee] = await hre.ethers.getSigners()
        const escrowFactory = await hre.ethers.getContractFactory("ERC20Escrow")
        const weth = await hre.ethers.getContract("WETH9")
        const escrow = new hre.ethers.Contract(contract, escrowFactory.interface, grantor)

        console.log("\n", "\t", "📲 Confirming receipt")

        const confirmReceiptTx = await escrow.getFunction("confirmReceipt").send()

        console.log("\t", `⏳ Waiting for ${blockConfirmations} block confirmations, please wait...`)

        await confirmReceiptTx.wait(blockConfirmations)

        console.log("\t", "✅ Receipt confirmed")

        const granteeWethBalance = await weth.getFunction("balanceOf").staticCallResult(grantee.address)
        const escrowBalance = await weth.getFunction("balanceOf").staticCallResult(await escrow.getAddress())
        console.log(
            "\t",
            `📲 Grantee WETH balance: ${hre.ethers.formatUnits(hre.ethers.toBigInt(granteeWethBalance[0]), "ether")}`,
        )
        console.log(
            "\t",
            `📲 Escrow contract WETH balance: ${hre.ethers.formatUnits(
                hre.ethers.toBigInt(escrowBalance[0]),
                "ether",
            )}`,
            "\n",
        )
    })
