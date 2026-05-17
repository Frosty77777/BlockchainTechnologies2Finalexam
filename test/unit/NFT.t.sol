// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AssetCertificateNFT} from "../../contracts/tokens/AssetCertificateNFT.sol";

contract NFTTest is Test {
    AssetCertificateNFT nft;
    address admin = makeAddr("admin");

    function setUp() public {
        nft = new AssetCertificateNFT(admin);
    }

    function test_onboardAsset() public {
        vm.prank(admin);
        uint256 id = nft.onboardAsset(admin, "ipfs://meta");
        assertEq(id, 1);
        assertEq(uint8(nft.assetState(id)), uint8(AssetCertificateNFT.AssetState.Active));
    }

    function test_setAssetState() public {
        vm.prank(admin);
        uint256 id = nft.onboardAsset(admin, "ipfs://meta");
        vm.prank(admin);
        nft.setAssetState(id, AssetCertificateNFT.AssetState.Suspended);
        assertEq(uint8(nft.assetState(id)), uint8(AssetCertificateNFT.AssetState.Suspended));
    }

    function test_tokenURI() public {
        vm.prank(admin);
        uint256 id = nft.onboardAsset(admin, "ipfs://x");
        assertEq(nft.tokenURI(id), "ipfs://x");
    }
}
