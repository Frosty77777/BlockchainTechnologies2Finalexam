// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @dev VULNERABLE — unguarded admin setter (access control case study).
contract InsecureAccess {
    address public admin;
    uint256 public feeBps;

    constructor() {
        admin = msg.sender;
    }

    function setFeeBps(uint256 newFee) external {
        feeBps = newFee;
    }
}
