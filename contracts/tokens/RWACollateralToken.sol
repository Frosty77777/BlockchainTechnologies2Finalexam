// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ProofOfReserveOracle} from "../oracles/ProofOfReserveOracle.sol";

/// @notice ERC-20 asset-backed token with role-gated minting for authorized issuers.
/// @dev Lifecycle: onboarded asset → issuer mints against PoR → burn on redemption.
contract RWACollateralToken is ERC20, AccessControl, Pausable {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    ProofOfReserveOracle public immutable proofOfReserve;
    string public assetId;

    event Minted(address indexed issuer, address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);

    error ZeroAmount();

    constructor(
        string memory name_,
        string memory symbol_,
        string memory assetId_,
        address proofOfReserve_,
        address admin,
        address issuer
    ) ERC20(name_, symbol_) {
        assetId = assetId_;
        proofOfReserve = ProofOfReserveOracle(proofOfReserve_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ISSUER_ROLE, issuer);
        _grantRole(PAUSER_ROLE, admin);
    }

    /// @inheritdoc Checks-Effects-Interactions: validate → mint → emit
    function mint(address to, uint256 amount) external onlyRole(ISSUER_ROLE) whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        proofOfReserve.assertSufficientReserve(totalSupply() + amount);
        _mint(to, amount);
        emit Minted(msg.sender, to, amount);
    }

    function burn(uint256 amount) external whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        _burn(msg.sender, amount);
        emit Burned(msg.sender, amount);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
