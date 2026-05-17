// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MockChainlinkAggregator} from "../../contracts/oracles/MockChainlinkAggregator.sol";
import {ProofOfReserveOracle} from "../../contracts/oracles/ProofOfReserveOracle.sol";
import {ChainlinkPriceOracle} from "../../contracts/oracles/ChainlinkPriceOracle.sol";
import {RWACollateralToken} from "../../contracts/tokens/RWACollateralToken.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";

abstract contract BaseTest is Test {
    MockChainlinkAggregator internal porFeed;
    ProofOfReserveOracle internal porOracle;
    ChainlinkPriceOracle internal priceOracle;
    RWACollateralToken internal rwa;
    MockERC20 internal asset;

    address internal admin = makeAddr("admin");
    address internal issuer = makeAddr("issuer");
    address internal user = makeAddr("user");

    function setUpBase() internal {
        porFeed = new MockChainlinkAggregator(8, 10_000_000e8);
        porOracle = new ProofOfReserveOracle(address(porFeed), 3600, admin);
        priceOracle = new ChainlinkPriceOracle(address(new MockChainlinkAggregator(8, 2000e8)), 3600, admin);
        rwa = new RWACollateralToken("Test RWA", "tRWA", "TEST-1", address(porOracle), admin, issuer);
        asset = new MockERC20("Asset", "AST", 18);
        asset.mint(user, 1_000_000 ether);
    }
}
