import { task, types } from "hardhat/config"
import { HardhatRuntimeEnvironment } from "hardhat/types"

task("start-dispute", "Starts a dispute in the Escrow contract")
    .addParam("contract", "Address of the Escrow", undefined, types.string, false)
    .setAction(async ({ contract }, hre: HardhatRuntimeEnvironment) => {
        const blockConfirmations = (await hre.getChainId()) === "31337" ? 1 : 3
        const [grantee] = await hre.ethers.getSigners()
        const escrowFactory = await hre.ethers.getContractFactory("ERC20Escrow")
        const escrow = new hre.ethers.Contract(contract, escrowFactory.interface, grantee)

        console.log("\n", "\t", `📲 Grantee is starting a dispute`)

        const startDisputeTx = await escrow.getFunction("startDispute").send()

        console.log("\t", `⏳ Waiting for ${blockConfirmations} block confirmations, please wait...`)

        await startDisputeTx.wait(blockConfirmations)

        console.log("\t", `✅ Dispute started, waiting for arbiter resolution`)
        console.log(
            "\n",
            "\t",
            `📲 Run: yarn hardhat resolve-dispute --contract ${await escrow.getAddress()} --refund grantor_refund --network evm_chain`,
            "\n",
        )
    })
