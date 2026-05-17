// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RWATokenV1} from "./RWATokenV1.sol";

/// @notice UUPS V2 — adds max supply cap without storage collision (new slot appended).
contract RWATokenV2 is RWATokenV1 {
    uint256 public maxSupply;
    uint256 public version;

    function initializeV2(uint256 maxSupply_) external reinitializer(2) {
        maxSupply = maxSupply_;
        version = 2;
    }

    function mint(address to, uint256 amount) public override onlyRole(MINTER_ROLE) {
        require(totalSupply() + amount <= maxSupply, "RWATokenV2: cap exceeded");
        super.mint(to, amount);
    }
}
