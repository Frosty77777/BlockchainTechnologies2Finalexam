// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ConstantProductAMM} from "../../contracts/amm/ConstantProductAMM.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

contract AMMInvariantTest is StdInvariant, Test {
    ConstantProductAMM amm;
    uint256 k0;

    function setUp() public {
        MockERC20 t0 = new MockERC20("T0", "T0", 18);
        MockERC20 t1 = new MockERC20("T1", "T1", 18);
        amm = new ConstantProductAMM(address(t0), address(t1));
        address lp = makeAddr("lp");
        t0.mint(lp, 1e24);
        t1.mint(lp, 1e24);
        vm.startPrank(lp);
        t0.approve(address(amm), 1e22);
        t1.approve(address(amm), 1e22);
        amm.addLiquidity(1e22, 1e22, lp);
        vm.stopPrank();
        k0 = amm.reserve0() * amm.reserve1();
        targetContract(address(amm));
    }

    function invariant_kNeverDecreases() public view {
        assertGe(amm.reserve0() * amm.reserve1(), k0);
    }
}
