// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @notice ERC-721 certificate for onboarded real-world assets (metadata URI = off-chain dossier).
contract AssetCertificateNFT is ERC721, AccessControl {
    bytes32 public constant ONBOARDER_ROLE = keccak256("ONBOARDER_ROLE");

    uint256 public nextTokenId;
    mapping(uint256 => string) public assetMetadataURI;

    enum AssetState {
        Pending,
        Active,
        Suspended,
        Retired
    }

    mapping(uint256 => AssetState) public assetState;

    event AssetOnboarded(uint256 indexed tokenId, string metadataURI);
    event AssetStateChanged(uint256 indexed tokenId, AssetState newState);

    error InvalidStateTransition();

    constructor(address admin) ERC721("RWA Asset Certificate", "RWACERT") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ONBOARDER_ROLE, admin);
    }

    function onboardAsset(address to, string calldata metadataURI)
        external
        onlyRole(ONBOARDER_ROLE)
        returns (uint256 tokenId)
    {
        tokenId = ++nextTokenId;
        assetMetadataURI[tokenId] = metadataURI;
        assetState[tokenId] = AssetState.Active;
        _safeMint(to, tokenId);
        emit AssetOnboarded(tokenId, metadataURI);
    }

    function setAssetState(uint256 tokenId, AssetState newState) external onlyRole(DEFAULT_ADMIN_ROLE) {
        AssetState current = assetState[tokenId];
        if (newState == current) revert InvalidStateTransition();
        assetState[tokenId] = newState;
        emit AssetStateChanged(tokenId, newState);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return assetMetadataURI[tokenId];
    }
}
