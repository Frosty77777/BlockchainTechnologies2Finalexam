// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "../helpers/BaseTest.sol";

contract SupplyInvariantTest is BaseTest {
    function setUp() public {
        setUpBase();
    }

    function invariant_supplyNotExceedReserve() public view {
        (uint256 reserve,) = porOracle.getReserve();
        assertLe(rwa.totalSupply(), reserve);
    }
}
