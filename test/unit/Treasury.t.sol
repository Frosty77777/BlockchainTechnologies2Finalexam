// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ProtocolTreasury} from "../../contracts/treasury/ProtocolTreasury.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";

contract TreasuryTest is Test {
    ProtocolTreasury treasury;
    MockERC20 token;
    address timelock = makeAddr("timelock");
    address beneficiary = makeAddr("ben");

    function setUp() public {
        treasury = new ProtocolTreasury(timelock);
        token = new MockERC20("T", "T", 18);
        token.mint(address(this), 100 ether);
    }

    function test_deposit() public {
        token.approve(address(treasury), 10 ether);
        treasury.deposit(address(token), 10 ether);
        assertEq(token.balanceOf(address(treasury)), 10 ether);
    }

    function test_pullWithdrawal() public {
        token.approve(address(treasury), 10 ether);
        treasury.deposit(address(token), 10 ether);
        vm.prank(timelock);
        treasury.scheduleWithdrawal(address(token), beneficiary, 5 ether);
        vm.prank(beneficiary);
        treasury.claimWithdrawal(address(token));
        assertEq(token.balanceOf(beneficiary), 5 ether);
    }
}
