import { HardhatRuntimeEnvironment } from "hardhat/types"
import { task, types } from "hardhat/config"
import "dotenv/config"

task("approve-and-mint", "Approve Escrow contract as spender in token used as payment")
    .addParam("spender", "Address of the spender", undefined, types.string, false)
    .addParam("amount", "Amount of ether to deposit and approve in WETH contract", undefined, types.string, false)
    .setAction(async ({ spender, amount }, hre: HardhatRuntimeEnvironment) => {
        const blockConfirmations = (await hre.getChainId()) === "31337" ? 1 : 3
        const [grantor] = await hre.ethers.getSigners()
        const mockWeth = await hre.ethers.getContract("WETH9", grantor)

        // console.log("\n", "\t", `📲 Depositing ${amount} ETH in WETH contract`)

        // const depositTx = await mockWeth.getFunction("deposit").send({ value: hre.ethers.parseEther(amount) })
        // await depositTx.wait(blockConfirmations)

        console.log("\t", `📲 Granting ${amount} ETH as allowance to EscrowFactory contract at ${spender}`)

        const allowanceTx = await mockWeth.getFunction("approve").send(spender, hre.ethers.parseEther(amount))
        await allowanceTx.wait(blockConfirmations)

        const balance = await mockWeth.getFunction("balanceOf").staticCallResult(grantor.address)
        console.log(
            "\t",
            `✅ Token balance: ${hre.ethers.formatUnits(hre.ethers.toBigInt(balance[0]), "ether")} WETH`,
            "\n",
        )
    })
