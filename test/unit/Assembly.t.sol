// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AssemblyUtils} from "../../contracts/utils/AssemblyUtils.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";

contract AssemblyHarness {
    mapping(address => uint256) internal balances;

    function setBalance(address a, uint256 v) external {
        balances[a] = v;
    }

    function readAsm(address a) external view returns (uint256) {
        return AssemblyUtils.balanceOfAssembly(a);
    }

    function readSol(address a) external view returns (uint256) {
        return AssemblyUtils.balanceOfSolidity(balances, a);
    }
}

contract AssemblyTest is Test {
    AssemblyHarness h;
    address user = makeAddr("user");

    function setUp() public {
        h = new AssemblyHarness();
        h.setBalance(user, 42 ether);
    }

    function test_balance_reads_match() public view {
        assertEq(h.readAsm(user), h.readSol(user));
    }

    function test_mul_equivalence() public pure {
        assertEq(AssemblyUtils.mulAsm(3, 4), AssemblyUtils.mulSolidity(3, 4));
    }

    function testFuzz_mul(uint128 x, uint128 y) public pure {
        vm.assume(x > 0 && y > 0 && uint256(x) * y < type(uint256).max);
        assertEq(AssemblyUtils.mulAsm(x, y), AssemblyUtils.mulSolidity(x, y));
    }
}
