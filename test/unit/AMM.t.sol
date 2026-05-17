// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ConstantProductAMM} from "../../contracts/amm/ConstantProductAMM.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";

contract AMMTest is Test {
    ConstantProductAMM amm;
    MockERC20 token0;
    MockERC20 token1;
    address lp = makeAddr("lp");

    function setUp() public {
        token0 = new MockERC20("T0", "T0", 18);
        token1 = new MockERC20("T1", "T1", 18);
        amm = new ConstantProductAMM(address(token0), address(token1));
        token0.mint(lp, 1000 ether);
        token1.mint(lp, 1000 ether);
    }

    function test_addLiquidity_mintsLp() public {
        vm.startPrank(lp);
        token0.approve(address(amm), 100 ether);
        token1.approve(address(amm), 100 ether);
        uint256 liq = amm.addLiquidity(100 ether, 100 ether, lp);
        vm.stopPrank();
        assertGt(liq, 0);
        assertEq(amm.reserve0(), 100 ether);
    }

    function test_swap_token0ForToken1() public {
        _seedPool();
        address trader = makeAddr("trader");
        token1.mint(trader, 100 ether);
        vm.startPrank(trader);
        token1.approve(address(amm), 10 ether);
        amm.swap(0, 5 ether, trader, type(uint256).max, 10 ether);
        vm.stopPrank();
        assertGt(token0.balanceOf(trader), 0);
    }

    function test_removeLiquidity() public {
        vm.startPrank(lp);
        token0.approve(address(amm), 100 ether);
        token1.approve(address(amm), 100 ether);
        uint256 liq = amm.addLiquidity(100 ether, 100 ether, lp);
        amm.removeLiquidity(liq, lp);
        vm.stopPrank();
        assertEq(amm.totalSupply(), 0);
    }

    function test_getAmountOut() public view {
        _seedPool();
        uint256 out = amm.getAmountOut(1 ether, amm.reserve1(), amm.reserve0());
        assertGt(out, 0);
    }

    function _seedPool() internal {
        vm.startPrank(lp);
        token0.approve(address(amm), 500 ether);
        token1.approve(address(amm), 500 ether);
        amm.addLiquidity(500 ether, 500 ether, lp);
        vm.stopPrank();
    }
}
