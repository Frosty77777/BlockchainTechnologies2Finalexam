// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {RWATokenV1} from "../../contracts/upgradeable/RWATokenV1.sol";
import {RWATokenV2} from "../../contracts/upgradeable/RWATokenV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeTest is Test {
    RWATokenV1 implV1;
    RWATokenV2 implV2;
    RWATokenV1 proxy;
    address admin = makeAddr("admin");

    function setUp() public {
        implV1 = new RWATokenV1();
        bytes memory data = abi.encodeCall(RWATokenV1.initialize, ("U", "U", admin));
        proxy = RWATokenV1(address(new ERC1967Proxy(address(implV1), data)));
        implV2 = new RWATokenV2();
    }

    function test_upgradeToV2_enforcesCap() public {
        vm.prank(admin);
        proxy.upgradeToAndCall(address(implV2), abi.encodeCall(RWATokenV2.initializeV2, (1000 ether)));
        RWATokenV2 v2 = RWATokenV2(address(proxy));
        assertEq(v2.version(), 2);
        vm.prank(admin);
        v2.mint(admin, 100 ether);
        vm.prank(admin);
        vm.expectRevert();
        v2.mint(admin, 1000 ether);
    }
}
