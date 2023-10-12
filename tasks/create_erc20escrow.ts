import { HardhatRuntimeEnvironment } from "hardhat/types"
import { task, types } from "hardhat/config"

task("create-erc20-escrow", "Creates a new escrow")
    .addParam(
        "token",
        "Address of the token used as payment. Example: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
        undefined,
        types.string,
        false,
    )
    .addParam(
        "fee",
        "Percentage from the payment charged by the arbiter to resolve a dispute, must be a value from 1 to 12. Example: 0.5 or 5",
        undefined,
        types.string,
        false,
    )
    .addParam(
        "payment",
        "Agreed upon amount of token to pay to the grantee. Example: 0.5 or 4",
        undefined,
        types.string,
        false,
    )
    .addParam("salt", "Arbitrary value provided by the caller. Example: 'Some Salt'", undefined, types.string, false)
    .addParam("duration", "Length of the escrow passed in seconds. Example: 3600", undefined, types.string, false)
    .setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
        const chainId = await hre.getChainId()
        const blockConfirmations = chainId === "31337" ? 1 : 3
        const [grantor, grantee, arbiter] = await hre.ethers.getSigners()
        const escrowFactory = await hre.ethers.getContract("EscrowFactory", grantor)

        console.log("\n", "\t", `📲 Creating new ERC20Escrow`)

        const createEscrowTx = await escrowFactory
            .getFunction("createERC20Escrow")
            .send(
                grantee.address,
                arbiter.address,
                taskArgs.token,
                BigInt(taskArgs.fee),
                hre.ethers.parseEther(taskArgs.payment),
                hre.ethers.encodeBytes32String(taskArgs.salt),
                BigInt(taskArgs.duration),
            )

        const txReceipt = await createEscrowTx.wait(blockConfirmations)

        console.log("\t", `⏳ Waiting for ${blockConfirmations} block confirmations, please wait...`)
        console.log("\t", `✅ Escrow created at address ${"0x" + txReceipt?.logs[0].topics[2].slice(-40)}`, "\n")
    })
