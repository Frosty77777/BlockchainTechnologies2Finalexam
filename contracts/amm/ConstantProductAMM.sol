// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice Constant-product AMM (x·y=k) with 0.3% swap fee and LP ERC-20.
contract ConstantProductAMM is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant FEE_BPS = 30; // 0.3%
    uint256 private constant BPS = 10_000;

    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint256 public reserve0;
    uint256 public reserve1;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1, uint256 liquidity);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, uint256 liquidity);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);

    error InsufficientLiquidity();
    error InsufficientOutput();
    error InvalidAmount();
    error KInvariantViolated();

    constructor(address token0_, address token1_) ERC20("RWA AMM LP", "RWA-LP") {
        token0 = IERC20(token0_);
        token1 = IERC20(token1_);
    }

    function addLiquidity(uint256 amount0Desired, uint256 amount1Desired, address to)
        external
        nonReentrant
        returns (uint256 liquidity)
    {
        token0.safeTransferFrom(msg.sender, address(this), amount0Desired);
        token1.safeTransferFrom(msg.sender, address(this), amount1Desired);

        uint256 _reserve0 = reserve0;
        uint256 _reserve1 = reserve1;

        if (_reserve0 == 0 && _reserve1 == 0) {
            liquidity = _sqrt(amount0Desired * amount1Desired);
            if (liquidity == 0) revert InsufficientLiquidity();
        } else {
            uint256 amount0Optimal = (amount1Desired * _reserve0) / _reserve1;
            if (amount0Optimal <= amount0Desired) {
                if (amount0Optimal == 0) revert InvalidAmount();
                liquidity = (amount0Optimal * totalSupply()) / _reserve0;
            } else {
                uint256 amount1Optimal = (amount0Desired * _reserve1) / _reserve0;
                if (amount1Optimal == 0) revert InvalidAmount();
                liquidity = (amount1Optimal * totalSupply()) / _reserve1;
            }
        }

        if (liquidity == 0) revert InsufficientLiquidity();
        _mint(to, liquidity);
        reserve0 = _reserve0 + amount0Desired;
        reserve1 = _reserve1 + amount1Desired;
        emit Mint(msg.sender, amount0Desired, amount1Desired, liquidity);
    }

    function removeLiquidity(uint256 liquidity, address to)
        external
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        if (liquidity == 0) revert InvalidAmount();
        uint256 _totalSupply = totalSupply();
        amount0 = (liquidity * reserve0) / _totalSupply;
        amount1 = (liquidity * reserve1) / _totalSupply;
        _burn(msg.sender, liquidity);
        reserve0 -= amount0;
        reserve1 -= amount1;
        token0.safeTransfer(to, amount0);
        token1.safeTransfer(to, amount1);
        emit Burn(msg.sender, amount0, amount1, liquidity);
    }

    /// @param amount0Out Must be 0 if swapping token1 in, and vice versa.
    function swap(uint256 amount0Out, uint256 amount1Out, address to, uint256 amount0InMax, uint256 amount1InMax)
        external
        nonReentrant
        returns (uint256 amount0In, uint256 amount1In)
    {
        if (amount0Out == 0 && amount1Out == 0) revert InvalidAmount();
        if (amount0Out > 0 && amount1Out > 0) revert InvalidAmount();

        uint256 _reserve0 = reserve0;
        uint256 _reserve1 = reserve1;
        uint256 balance0Before = token0.balanceOf(address(this));
        uint256 balance1Before = token1.balanceOf(address(this));

        if (amount0Out > 0) {
            if (amount0Out >= _reserve0) revert InsufficientOutput();
            token0.safeTransfer(to, amount0Out);
            amount1In = _getAmountIn(amount0Out, _reserve1, _reserve0);
            if (amount1In > amount1InMax) revert InsufficientOutput();
            token1.safeTransferFrom(msg.sender, address(this), amount1In);
        } else {
            if (amount1Out >= _reserve1) revert InsufficientOutput();
            token1.safeTransfer(to, amount1Out);
            amount0In = _getAmountIn(amount1Out, _reserve0, _reserve1);
            if (amount0In > amount0InMax) revert InsufficientOutput();
            token0.safeTransferFrom(msg.sender, address(this), amount0In);
        }

        uint256 balance0After = token0.balanceOf(address(this));
        uint256 balance1After = token1.balanceOf(address(this));

        uint256 amount0Adjusted = (balance0After * BPS) - (balance0Before * (BPS - FEE_BPS));
        uint256 amount1Adjusted = (balance1After * BPS) - (balance1Before * (BPS - FEE_BPS));

        if (amount0Adjusted * amount1Adjusted < _reserve0 * _reserve1 * BPS * BPS) {
            revert KInvariantViolated();
        }

        reserve0 = balance0After;
        reserve1 = balance1After;
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        returns (uint256 amountOut)
    {
        uint256 amountInWithFee = amountIn * (BPS - FEE_BPS);
        amountOut = (amountInWithFee * reserveOut) / (reserveIn * BPS + amountInWithFee);
    }

    function _getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        return (reserveIn * amountOut * BPS) / ((reserveOut - amountOut) * (BPS - FEE_BPS)) + 1;
    }

    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y == 0) return 0;
        z = y;
        uint256 x = (y / 2) + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    }
}
