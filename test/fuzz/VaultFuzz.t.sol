// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {RWAYieldVault} from "../../contracts/vault/RWAYieldVault.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";

contract VaultFuzzTest is Test {
    RWAYieldVault vault;
    MockERC20 asset;

    function setUp() public {
        asset = new MockERC20("A", "A", 18);
        vault = new RWAYieldVault(asset, address(this), makeAddr("t"), 0);
    }

    function testFuzz_depositWithdrawRoundTrip(uint128 amount) public {
        amount = uint128(bound(amount, 1e12, 1e24));
        address u = makeAddr("u");
        asset.mint(u, amount);
        vm.startPrank(u);
        asset.approve(address(vault), amount);
        uint256 shares = vault.deposit(amount, u);
        uint256 back = vault.redeem(shares, u, u);
        vm.stopPrank();
        assertLe(back, amount + 1);
        assertGe(back + 1, amount);
    }

    function testFuzz_convertRoundTrip(uint128 amount) public {
        amount = uint128(bound(amount, 1, 1e22));
        uint256 shares = vault.convertToShares(amount);
        uint256 assets = vault.convertToAssets(shares);
        assertApproxEqAbs(assets, amount, 1);
    }
}
