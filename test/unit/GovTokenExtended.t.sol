// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {RWAGovernanceToken} from "../../contracts/tokens/RWAGovernanceToken.sol";

contract GovTokenExtendedTest is Test {
    RWAGovernanceToken token;
    address a = makeAddr("a");
    address b = makeAddr("b");

    function setUp() public {
        token = new RWAGovernanceToken(a);
    }

    function test_name() public view {
        assertEq(token.name(), "RWA Governance");
    }

    function test_symbol() public view {
        assertEq(token.symbol(), "RWAGOV");
    }

    function test_initialBalance() public view {
        assertEq(token.balanceOf(a), 1_000_000 ether);
    }

    function test_transfer() public {
        vm.prank(a);
        token.transfer(b, 100 ether);
        assertEq(token.balanceOf(b), 100 ether);
    }

    function test_delegate_self() public {
        vm.prank(a);
        token.delegate(a);
        assertEq(token.getVotes(a), 1_000_000 ether);
    }

    function test_delegate_other() public {
        vm.prank(a);
        token.delegate(b);
        assertEq(token.getVotes(b), 1_000_000 ether);
    }

    function test_delegates() public {
        vm.prank(a);
        token.delegate(b);
        assertEq(token.delegates(a), b);
    }

    function test_clock() public view {
        assertEq(token.clock(), block.timestamp);
    }

    function test_CLOCK_MODE() public view {
        bytes memory mode = token.CLOCK_MODE();
        assertGt(mode.length, 0);
    }

    function test_totalSupply() public view {
        assertEq(token.totalSupply(), 1_000_000 ether);
    }

    function test_approve_allowance() public {
        vm.prank(a);
        token.approve(b, 50 ether);
        assertEq(token.allowance(a, b), 50 ether);
    }

    function test_transferFrom() public {
        vm.prank(a);
        token.approve(b, 10 ether);
        vm.prank(b);
        token.transferFrom(a, b, 10 ether);
        assertEq(token.balanceOf(b), 10 ether);
    }
}
