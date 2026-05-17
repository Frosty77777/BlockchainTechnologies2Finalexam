// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IChainlinkAggregator} from "../interfaces/IChainlinkAggregator.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @notice Oracle adapter with staleness checks — Pattern: Oracle adapter / interface abstraction.
contract ChainlinkPriceOracle is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IChainlinkAggregator public immutable feed;
    uint256 public immutable maxStaleness;

    event PriceUpdated(int256 price, uint256 updatedAt);

    error StalePrice(uint256 updatedAt, uint256 maxAllowed);
    error InvalidPrice(int256 answer);

    constructor(address feed_, uint256 maxStalenessSeconds_, address admin) {
        feed = IChainlinkAggregator(feed_);
        maxStaleness = maxStalenessSeconds_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    /// @dev Reverts if price is stale or non-positive.
    function getPrice() external view returns (uint256 price, uint256 updatedAt) {
        (, int256 answer,, uint256 ts,) = feed.latestRoundData();
        if (answer <= 0) revert InvalidPrice(answer);
        if (block.timestamp > ts + maxStaleness) revert StalePrice(ts, maxStaleness);
        return (uint256(answer), ts);
    }

    function decimals() external view returns (uint8) {
        return feed.decimals();
    }
}
