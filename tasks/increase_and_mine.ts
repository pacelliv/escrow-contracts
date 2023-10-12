import { task, types } from "hardhat/config"
import { HardhatRuntimeEnvironment } from "hardhat/types"

task("increase-and-mine", "Increases the time in the local node and mines a block")
    .setDescription("This task is only meant to be used on the local node")
    .addParam("time", "Number of seconds to jump in time", undefined, types.int, false)
    .setAction(async ({ time }, hre: HardhatRuntimeEnvironment) => {
        await hre.network.provider.request({ method: "evm_increaseTime", params: [time] })
        await hre.network.provider.request({ method: "evm_mine", params: [] })
        console.log("\n", "\t", `Increased timestamp by ${time} seconds and mined a block`, "\n")
    })
