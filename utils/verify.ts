import { run } from "hardhat"

const verify = async (contractAddress: string, args: any[]) => {
    console.log(`Verifying contract at ${contractAddress}, please wait...`)
    try {
        await run("verify:verify", {
            address: contractAddress,
            constructorArgs: args,
        })
    } catch (error: any) {
        if (error.toLowerCase().includes("already verified")) {
            console.log("Contract already verified")
        } else {
            console.log(error)
        }
    }
}

export default verify
