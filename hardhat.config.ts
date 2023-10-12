import { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import "@nomicfoundation/hardhat-foundry"
import "dotenv/config"
import "hardhat-deploy"
import "hardhat-deploy-ethers"
import "./tasks"

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || ""
const PRIVATE_KEY_A = process.env.PRIVATE_KEY_A || ""
const PRIVATE_KEY_B = process.env.PRIVATE_KEY_B || ""
const PRIVATE_KEY_C = process.env.PRIVATE_KEY_C || ""
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || ""
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY || ""
const REPORT_GAS = process.env.REPORT_GAS || ""

const config: HardhatUserConfig = {
    solidity: {
        compilers: [
            {
                version: "0.8.21",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
        },
        sepolia: {
            url: SEPOLIA_RPC_URL,
            accounts: [PRIVATE_KEY_A, PRIVATE_KEY_B, PRIVATE_KEY_C],
            chainId: 11155111,
        },
    },
    etherscan: {
        apiKey: ETHERSCAN_API_KEY,
    },
    gasReporter: {
        currency: "USD",
        gasPrice: 100,
        enabled: REPORT_GAS === "true" ? true : false,
        coinmarketcap: COINMARKETCAP_API_KEY,
        outputFile: "gas_report.txt",
        noColors: true,
    },
    namedAccounts: {
        grantor: 0,
        grantee: 1,
        arbiter: 2,
        deployer: 3,
    },
    paths: {
        sources: "src",
    },
    mocha: {
        timeout: 300000,
    },
}

export default config
