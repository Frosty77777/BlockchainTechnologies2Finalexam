// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "../helpers/BaseTest.sol";
import {RWACollateralToken} from "../../contracts/tokens/RWACollateralToken.sol";

contract RWACollateralTest is BaseTest {
    function setUp() public {
        setUpBase();
    }

    function test_mint_byIssuer() public {
        vm.prank(issuer);
        rwa.mint(user, 100 ether);
        assertEq(rwa.balanceOf(user), 100 ether);
    }

    function test_mint_revertsNonIssuer() public {
        vm.prank(user);
        vm.expectRevert();
        rwa.mint(user, 1 ether);
    }

    function test_mint_revertsZero() public {
        vm.prank(issuer);
        vm.expectRevert(RWACollateralToken.ZeroAmount.selector);
        rwa.mint(user, 0);
    }

    function test_mint_revertsInsufficientReserve() public {
        porFeed.setAnswer(1);
        vm.prank(issuer);
        vm.expectRevert();
        rwa.mint(user, 10 ether);
    }

    function test_burn() public {
        vm.prank(issuer);
        rwa.mint(user, 50 ether);
        vm.prank(user);
        rwa.burn(20 ether);
        assertEq(rwa.balanceOf(user), 30 ether);
    }

    function test_pause_blocksMint() public {
        vm.prank(admin);
        rwa.pause();
        vm.prank(issuer);
        vm.expectRevert();
        rwa.mint(user, 1 ether);
    }

    function test_unpause_allowsMint() public {
        vm.startPrank(admin);
        rwa.pause();
        rwa.unpause();
        vm.stopPrank();
        vm.prank(issuer);
        rwa.mint(user, 1 ether);
        assertEq(rwa.totalSupply(), 1 ether);
    }

    function test_assetId() public view {
        assertEq(rwa.assetId(), "TEST-1");
    }
}
