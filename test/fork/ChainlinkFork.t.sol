// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ChainlinkPriceOracle} from "../../contracts/oracles/ChainlinkPriceOracle.sol";
import {IChainlinkAggregator} from "../../contracts/interfaces/IChainlinkAggregator.sol";

/// @dev Fork tests — set ARBITRUM_SEPOLIA_RPC_URL to run against live feeds.
contract ChainlinkForkTest is Test {
    address constant ARB_SEPOLIA_ETH_USD = 0x62CAe0FA2da220f43a51f86Db2EDb36DcA9A5A08;

    function test_fork_ethUsdFeed() public {
        string memory rpc = vm.envOr("ARBITRUM_SEPOLIA_RPC_URL", string(""));
        if (bytes(rpc).length == 0) {
            vm.skip(true);
        }
        vm.createSelectFork(rpc);
        ChainlinkPriceOracle oracle = new ChainlinkPriceOracle(ARB_SEPOLIA_ETH_USD, 86400, address(this));
        (uint256 price,) = oracle.getPrice();
        assertGt(price, 0);
    }

    function test_fork_aggregatorInterface() public {
        string memory rpc = vm.envOr("ARBITRUM_SEPOLIA_RPC_URL", string(""));
        if (bytes(rpc).length == 0) vm.skip(true);
        vm.createSelectFork(rpc);
        (, int256 answer,,,) = IChainlinkAggregator(ARB_SEPOLIA_ETH_USD).latestRoundData();
        assertGt(answer, 0);
    }
}
