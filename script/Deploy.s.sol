// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

import {BonklerPool} from "src/BonklerPool.sol";

/// @notice A very simple deployment script
contract Deploy is Script {
    /// @notice The main script entrypoint
    /// @return pool The deployed contract
    function run() external returns (BonklerPool pool) {
        vm.startBroadcast();
        pool = new BonklerPool();
        vm.stopBroadcast();
    }
}
