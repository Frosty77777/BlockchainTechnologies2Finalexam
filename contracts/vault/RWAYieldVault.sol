// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice ERC-4626 yield vault over RWA collateral tokens — fee accrues to treasury via yield bps.
contract RWAYieldVault is ERC4626, AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant YIELD_MANAGER_ROLE = keccak256("YIELD_MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public yieldBps;
    address public treasury;

    event YieldHarvested(uint256 amount, address indexed treasury);
    event YieldBpsUpdated(uint256 oldBps, uint256 newBps);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

    error DepositWhilePaused();
    error WithdrawWhilePaused();

    constructor(IERC20 asset_, address admin, address treasury_, uint256 yieldBps_)
        ERC20("RWA Yield Vault Share", "rwavUSDC")
        ERC4626(asset_)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(YIELD_MANAGER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        treasury = treasury_;
        yieldBps = yieldBps_;
    }

    function setYieldBps(uint256 newBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 old = yieldBps;
        yieldBps = newBps;
        emit YieldBpsUpdated(old, newBps);
    }

    function setTreasury(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address old = treasury;
        treasury = newTreasury;
        emit TreasuryUpdated(old, newTreasury);
    }

    /// @notice Simulated yield injection — in production funded by off-chain revenue stream.
    function reportYield(uint256 amount) external onlyRole(YIELD_MANAGER_ROLE) nonReentrant {
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), amount);
        uint256 fee = (amount * yieldBps) / 10_000;
        if (fee > 0) {
            IERC20(asset()).safeTransfer(treasury, fee);
        }
        emit YieldHarvested(fee, treasury);
    }

    function deposit(uint256 assets, address receiver)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256 shares)
    {
        return super.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256 assets)
    {
        return super.mint(shares, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256 shares)
    {
        return super.withdraw(assets, receiver, owner);
    }

    function redeem(uint256 shares, address receiver, address owner)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256 assets)
    {
        return super.redeem(shares, receiver, owner);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
