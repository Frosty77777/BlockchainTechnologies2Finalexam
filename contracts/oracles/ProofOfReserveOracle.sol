// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IChainlinkAggregator} from "../interfaces/IChainlinkAggregator.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @notice Chainlink-style Proof of Reserve feed wrapper for collateral backing checks.
contract ProofOfReserveOracle is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IChainlinkAggregator public immutable reserveFeed;
    uint256 public immutable maxStaleness;

    error StaleReserve(uint256 updatedAt);
    error InsufficientReserve(uint256 offChainReserve, uint256 required);

    constructor(address reserveFeed_, uint256 maxStalenessSeconds_, address admin) {
        reserveFeed = IChainlinkAggregator(reserveFeed_);
        maxStaleness = maxStalenessSeconds_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    function getReserve() public view returns (uint256 reserve, uint256 updatedAt) {
        (, int256 answer,, uint256 ts,) = reserveFeed.latestRoundData();
        if (block.timestamp > ts + maxStaleness) revert StaleReserve(ts);
        return (uint256(answer), ts);
    }

    /// @dev Ensures reported off-chain reserve covers requested mint amount (same decimals).
    function assertSufficientReserve(uint256 requiredAmount) external view {
        (uint256 reserve,) = getReserve();
        if (reserve < requiredAmount) revert InsufficientReserve(reserve, requiredAmount);
    }
}
