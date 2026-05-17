// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {RWAYieldVault} from "../../contracts/vault/RWAYieldVault.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultTest is Test {
    RWAYieldVault vault;
    MockERC20 asset;
    address admin = makeAddr("admin");
    address treasury = makeAddr("treasury");
    address user = makeAddr("user");

    function setUp() public {
        asset = new MockERC20("A", "A", 18);
        vault = new RWAYieldVault(asset, admin, treasury, 500);
        asset.mint(user, 1000 ether);
    }

    function test_deposit_mintShares() public {
        vm.startPrank(user);
        asset.approve(address(vault), 100 ether);
        uint256 shares = vault.deposit(100 ether, user);
        vm.stopPrank();
        assertGt(shares, 0);
        assertEq(vault.balanceOf(user), shares);
    }

    function test_withdraw_returnsAssets() public {
        vm.startPrank(user);
        asset.approve(address(vault), 100 ether);
        uint256 shares = vault.deposit(100 ether, user);
        uint256 assets = vault.redeem(shares, user, user);
        vm.stopPrank();
        assertEq(assets, 100 ether);
    }

    function test_reportYield_sendsFeeToTreasury() public {
        address manager = admin;
        asset.mint(manager, 100 ether);
        vm.startPrank(manager);
        asset.approve(address(vault), 100 ether);
        vault.reportYield(100 ether);
        vm.stopPrank();
        assertEq(asset.balanceOf(treasury), 5 ether);
    }

    function test_pause_blocksDeposit() public {
        vm.prank(admin);
        vault.pause();
        vm.startPrank(user);
        asset.approve(address(vault), 1 ether);
        vm.expectRevert();
        vault.deposit(1 ether, user);
        vm.stopPrank();
    }

    function test_setYieldBps() public {
        vm.prank(admin);
        vault.setYieldBps(1000);
        assertEq(vault.yieldBps(), 1000);
    }

    function test_setTreasury() public {
        address t2 = makeAddr("t2");
        vm.prank(admin);
        vault.setTreasury(t2);
        assertEq(vault.treasury(), t2);
    }

    function test_previewDeposit_matchesDeposit() public {
        uint256 expected = vault.previewDeposit(50 ether);
        vm.startPrank(user);
        asset.approve(address(vault), 50 ether);
        uint256 shares = vault.deposit(50 ether, user);
        vm.stopPrank();
        assertEq(shares, expected);
    }
}
