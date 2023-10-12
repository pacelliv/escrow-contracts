import { task, types } from "hardhat/config"
import { HardhatRuntimeEnvironment } from "hardhat/types"

task("resolve-dispute", "Resolves a dispute and distribute funds")
    .addParam("contract", "Address of the Escrow", undefined, types.string, false)
    .addParam(
        "refund",
        "Percentage of the locked funds to refund the grantor, the value must be between 0 to 100",
        undefined,
        types.int,
        false,
    )
    .setAction(async ({ contract, refund }, hre: HardhatRuntimeEnvironment) => {
        const [grantor, grantee, arbiter] = await hre.ethers.getSigners()
        const blockConfirmations = (await hre.getChainId()) === "31337" ? 1 : 3
        const escrowFactory = await hre.ethers.getContractFactory("ERC20Escrow")
        const escrow = new hre.ethers.Contract(contract, escrowFactory.interface, arbiter)

        console.log("\n", "\t", `📲 Arbiter is resolving a dispute`)

        const resolveDisputeTx = await escrow.getFunction("resolveDispute").send(hre.ethers.toBigInt(refund))

        console.log("\t", `⏳ Waiting for ${blockConfirmations} block confirmations, please wait...`)

        await resolveDisputeTx.wait(blockConfirmations)

        console.log("\t", `✅ Dispute resolved`)

        const weth = await hre.ethers.getContract("WETH9")
        const grantorWethBalance = await weth.getFunction("balanceOf").staticCallResult(grantor.address)
        const granteeWethBalance = await weth.getFunction("balanceOf").staticCallResult(grantee.address)
        const arbiterWethBalance = await weth.getFunction("balanceOf").staticCallResult(arbiter.address)
        console.log("\n", "\t", `📲 Balances after resolved dispute:`)
        console.log(
            "\t",
            `📲 Grantor WETH balance: ${hre.ethers.formatUnits(hre.ethers.toBigInt(grantorWethBalance[0]), "ether")}`,
        )
        console.log(
            "\t",
            `📲 Grantee WETH balance: ${hre.ethers.formatUnits(hre.ethers.toBigInt(granteeWethBalance[0]), "ether")}`,
        )
        console.log(
            "\t",
            `📲 Arbiter WETH balance: ${hre.ethers.formatUnits(hre.ethers.toBigInt(arbiterWethBalance[0]), "ether")}`,
            "\n",
        )
    })
