// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RWACollateralToken} from "../tokens/RWACollateralToken.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

/// @notice Factory deploying collateral tokens via CREATE and CREATE2 — Pattern: Factory.
contract RWAAssetFactory {
    event AssetDeployed(address indexed token, string assetId, bool viaCreate2);

    address public immutable proofOfReserve;
    address public immutable admin;

    mapping(bytes32 => address) public saltToToken;

    constructor(address proofOfReserve_, address admin_) {
        proofOfReserve = proofOfReserve_;
        admin = admin_;
    }

    /// @dev Standard CREATE deployment.
    function deployWithCreate(string calldata name, string calldata symbol, string calldata assetId, address issuer)
        external
        returns (address token)
    {
        RWACollateralToken t = new RWACollateralToken(name, symbol, assetId, proofOfReserve, admin, issuer);
        token = address(t);
        emit AssetDeployed(token, assetId, false);
    }

    /// @dev CREATE2 for deterministic addresses (e.g. cross-chain parity).
    function deployWithCreate2(
        string calldata name,
        string calldata symbol,
        string calldata assetId,
        address issuer,
        bytes32 salt
    ) external returns (address token) {
        bytes memory bytecode = abi.encodePacked(
            type(RWACollateralToken).creationCode,
            abi.encode(name, symbol, assetId, proofOfReserve, admin, issuer)
        );
        token = Create2.deploy(0, salt, bytecode);
        saltToToken[salt] = token;
        emit AssetDeployed(token, assetId, true);
    }

    function predictCreate2Address(bytes32 salt, string calldata name, string calldata symbol, string calldata assetId, address issuer)
        external
        view
        returns (address)
    {
        bytes memory bytecode = abi.encodePacked(
            type(RWACollateralToken).creationCode,
            abi.encode(name, symbol, assetId, proofOfReserve, admin, issuer)
        );
        return Create2.computeAddress(salt, keccak256(bytecode));
    }
}
