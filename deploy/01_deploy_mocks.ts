import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import verify from "../utils/verify"
import "dotenv/config"

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts, getChainId } = hre
    const { deploy } = deployments
    const { grantor: deployer } = await getNamedAccounts()
    const chainId = await getChainId()

    const weth9Mock = await deploy("WETH9", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: chainId === "31337" ? 1 : 3,
    })

    if (chainId !== "31337" && process.env.ETHERSCAN_API_KEY) {
        await verify(weth9Mock.address, [])
    }
}

export default func
func.tags = ["mocks"]
