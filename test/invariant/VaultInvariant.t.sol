// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {RWAYieldVault} from "../../contracts/vault/RWAYieldVault.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";

contract VaultInvariantTest is Test {
    RWAYieldVault vault;
    MockERC20 asset;

    function setUp() public {
        asset = new MockERC20("A", "A", 18);
        vault = new RWAYieldVault(asset, address(this), makeAddr("t"), 0);
    }

    function invariant_totalAssetsMatchesBalance() public view {
        assertEq(vault.totalAssets(), asset.balanceOf(address(vault)));
    }

    function invariant_convertToShares_assetsRoundTrip() public view {
        uint256 assets = 1e18;
        if (vault.totalSupply() == 0) return;
        uint256 shares = vault.convertToShares(assets);
        assertApproxEqAbs(vault.convertToAssets(shares), assets, 2);
    }
}
