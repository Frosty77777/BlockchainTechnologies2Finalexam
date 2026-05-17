// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "../helpers/BaseTest.sol";
import {RWAAssetFactory} from "../../contracts/factory/RWAAssetFactory.sol";

contract FactoryTest is BaseTest {
    RWAAssetFactory factory;

    function setUp() public {
        setUpBase();
        factory = new RWAAssetFactory(address(porOracle), admin);
    }

    function test_deployWithCreate() public {
        address t = factory.deployWithCreate("A", "A", "ID", issuer);
        assertTrue(t != address(0));
    }

    function test_deployWithCreate2() public {
        bytes32 salt = keccak256("salt1");
        address t = factory.deployWithCreate2("B", "B", "ID2", issuer, salt);
        assertEq(factory.saltToToken(salt), t);
    }

    function test_predictCreate2_matchesDeploy() public {
        bytes32 salt = keccak256("salt2");
        address predicted = factory.predictCreate2Address(salt, "C", "C", "ID3", issuer);
        address deployed = factory.deployWithCreate2("C", "C", "ID3", issuer, salt);
        assertEq(predicted, deployed);
    }
}
