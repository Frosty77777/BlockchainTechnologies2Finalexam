// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ConstantProductAMM} from "../../contracts/amm/ConstantProductAMM.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";

contract AMMFuzzTest is Test {
    ConstantProductAMM amm;
    MockERC20 token0;
    MockERC20 token1;

    function setUp() public {
        token0 = new MockERC20("T0", "T0", 18);
        token1 = new MockERC20("T1", "T1", 18);
        amm = new ConstantProductAMM(address(token0), address(token1));
        address lp = makeAddr("lp");
        token0.mint(lp, 1_000_000 ether);
        token1.mint(lp, 1_000_000 ether);
        vm.startPrank(lp);
        token0.approve(address(amm), 100_000 ether);
        token1.approve(address(amm), 100_000 ether);
        amm.addLiquidity(100_000 ether, 100_000 ether, lp);
        vm.stopPrank();
    }

    function testFuzz_swapMaintainsReserves(uint96 amountIn) public {
        amountIn = uint96(bound(amountIn, 1e15, 1000 ether));
        address trader = makeAddr("trader");
        token1.mint(trader, amountIn);
        uint256 r0 = amm.reserve0();
        uint256 r1 = amm.reserve1();
        uint256 out = amm.getAmountOut(amountIn, r1, r0);
        if (out >= r0 || out == 0) return;
        vm.startPrank(trader);
        token1.approve(address(amm), amountIn);
        amm.swap(out, 0, trader, type(uint256).max, amountIn);
        vm.stopPrank();
        assertGe(amm.reserve0() * amm.reserve1(), r0 * r1);
    }

    function testFuzz_getAmountOut_bounded(uint96 amountIn, uint96 rIn, uint96 rOut) public {
        rIn = uint96(bound(rIn, 1e18, 1e24));
        rOut = uint96(bound(rOut, 1e18, 1e24));
        amountIn = uint96(bound(amountIn, 1, rIn / 10));
        uint256 out = amm.getAmountOut(amountIn, rIn, rOut);
        assertLt(out, rOut);
    }
}
