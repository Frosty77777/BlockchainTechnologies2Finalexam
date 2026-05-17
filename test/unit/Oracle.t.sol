// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "../helpers/BaseTest.sol";
import {MockChainlinkAggregator} from "../../contracts/oracles/MockChainlinkAggregator.sol";

contract OracleTest is BaseTest {
    function setUp() public {
        setUpBase();
    }

    function test_getPrice_succeeds() public view {
        (uint256 p,) = priceOracle.getPrice();
        assertEq(p, 2000e8);
    }

    function test_getPrice_revertsStale() public {
        MockChainlinkAggregator feed = MockChainlinkAggregator(address(priceOracle.feed()));
        feed.setUpdatedAt(block.timestamp - 4000);
        vm.expectRevert();
        priceOracle.getPrice();
    }

    function test_getPrice_revertsInvalid() public {
        MockChainlinkAggregator feed = MockChainlinkAggregator(address(priceOracle.feed()));
        feed.setAnswer(-1);
        vm.expectRevert();
        priceOracle.getPrice();
    }

    function test_por_getReserve() public view {
        (uint256 r,) = porOracle.getReserve();
        assertEq(r, 10_000_000e8);
    }

    function test_por_assertSufficient() public view {
        porOracle.assertSufficientReserve(1e8);
    }

    function test_por_revertsInsufficient() public {
        vm.expectRevert();
        porOracle.assertSufficientReserve(20_000_000e8);
    }

    function test_por_revertsStale() public {
        porFeed.setUpdatedAt(block.timestamp - 5000);
        vm.expectRevert();
        porOracle.getReserve();
    }

    function test_mock_setAnswer() public {
        porFeed.setAnswer(5e8);
        (uint256 r,) = porOracle.getReserve();
        assertEq(r, 5e8);
    }

    function test_priceOracle_decimals() public view {
        assertEq(priceOracle.decimals(), 8);
    }
}
