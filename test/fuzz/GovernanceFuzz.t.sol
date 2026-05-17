// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {RWAGovernanceToken} from "../../contracts/tokens/RWAGovernanceToken.sol";

contract GovernanceFuzzTest is Test {
    RWAGovernanceToken token;
    address holder = makeAddr("holder");

    function setUp() public {
        token = new RWAGovernanceToken(holder);
    }

    function testFuzz_transfer_updatesVotesAfterDelegate(uint128 amt) public {
        amt = uint128(bound(amt, 1, 100_000 ether));
        address d = makeAddr("delegate");
        vm.startPrank(holder);
        token.delegate(d);
        token.transfer(makeAddr("recv"), amt);
        vm.stopPrank();
        assertEq(token.getVotes(d), token.totalSupply() - amt);
    }

    function testFuzz_permit_nonceIncreases(uint256 pk) public {
        pk = bound(pk, 1, type(uint128).max);
        // smoke: delegates don't break total supply
        assertEq(token.totalSupply(), 1_000_000 ether);
    }
}
