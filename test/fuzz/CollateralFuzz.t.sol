// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "../helpers/BaseTest.sol";

contract CollateralFuzzTest is BaseTest {
    function setUp() public {
        setUpBase();
    }

    function testFuzz_mintWithinReserve(uint96 amount) public {
        amount = uint96(bound(amount, 1, 1_000_000e8));
        porFeed.setAnswer(int256(uint256(amount) * 2));
        vm.prank(issuer);
        rwa.mint(user, amount);
        assertEq(rwa.totalSupply(), amount);
    }
}
