// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {BonklerPool} from "src/BonklerPool.sol";

contract BonklerPoolTest is Test {
    using stdStorage for StdStorage;

    BonklerPool pool;

    function setUp() public payable {
        pool = new BonklerPool();
    }

    function testPool() public payable {}
}
