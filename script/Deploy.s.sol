// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {RWAGovernanceToken} from "../contracts/tokens/RWAGovernanceToken.sol";
import {AssetCertificateNFT} from "../contracts/tokens/AssetCertificateNFT.sol";
import {MockChainlinkAggregator} from "../contracts/oracles/MockChainlinkAggregator.sol";
import {ChainlinkPriceOracle} from "../contracts/oracles/ChainlinkPriceOracle.sol";
import {ProofOfReserveOracle} from "../contracts/oracles/ProofOfReserveOracle.sol";
import {RWAAssetFactory} from "../contracts/factory/RWAAssetFactory.sol";
import {RWAYieldVault} from "../contracts/vault/RWAYieldVault.sol";
import {ConstantProductAMM} from "../contracts/amm/ConstantProductAMM.sol";
import {ProtocolTreasury} from "../contracts/treasury/ProtocolTreasury.sol";
import {RWAGovernor} from "../contracts/governance/RWAGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {RWACollateralToken} from "../contracts/tokens/RWACollateralToken.sol";
import {MockERC20} from "../contracts/mocks/MockERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {RWATokenV1} from "../contracts/upgradeable/RWATokenV1.sol";

/// @notice Idempotent-ish deploy script for L2 testnet (Arbitrum Sepolia default).
/// @dev Set CHAINLINK feeds via env for production; uses mocks when USE_MOCK_ORACLES=true.
contract Deploy is Script {
    uint256 constant TIMELOCK_MIN_DELAY = 2 days;
    uint256 constant MAX_STALENESS = 3600;

    struct Deployment {
        address govToken;
        address timelock;
        address governor;
        address treasury;
        address priceOracle;
        address porOracle;
        address factory;
        address assetNft;
        address collateralToken;
        address vault;
        address amm;
        address upgradeableToken;
    }

    function run() external returns (Deployment memory d) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        d.govToken = address(new RWAGovernanceToken(deployer));

        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = address(0);
        executors[0] = address(0);
        d.timelock = address(new TimelockController(TIMELOCK_MIN_DELAY, proposers, executors, deployer));

        d.governor = address(new RWAGovernor(RWAGovernanceToken(d.govToken), TimelockController(payable(d.timelock))));

        d.treasury = address(new ProtocolTreasury(d.timelock));

        address priceFeed = _resolveFeed(vm.envOr("CHAINLINK_ETH_USD_FEED", address(0)), 8, 2000e8);
        address porFeed = _resolveFeed(vm.envOr("CHAINLINK_POR_FEED", address(0)), 8, 1_000_000e8);

        d.priceOracle = address(new ChainlinkPriceOracle(priceFeed, MAX_STALENESS, d.timelock));
        d.porOracle = address(new ProofOfReserveOracle(porFeed, MAX_STALENESS, d.timelock));

        d.factory = address(new RWAAssetFactory(d.porOracle, d.timelock));
        d.assetNft = address(new AssetCertificateNFT(d.timelock));

        d.collateralToken = address(
            new RWACollateralToken("RWA Gold Backed", "RWAGOLD", "GOLD-001", d.porOracle, d.timelock, deployer)
        );

        MockERC20 underlying = new MockERC20("Mock USD", "mUSD", 6);
        underlying.mint(deployer, 10_000_000e6);
        d.vault = address(new RWAYieldVault(underlying, d.timelock, d.treasury, 100));

        MockERC20 quote = new MockERC20("Quote USD", "qUSD", 18);
        d.amm = address(new ConstantProductAMM(d.collateralToken, address(quote)));

        RWATokenV1 impl = new RWATokenV1();
        bytes memory initData = abi.encodeCall(RWATokenV1.initialize, ("RWA Upgradeable", "RWAUP", d.timelock));
        d.upgradeableToken = address(new ERC1967Proxy(address(impl), initData));

        TimelockController(payable(d.timelock)).grantRole(TimelockController.PROPOSER_ROLE(), d.governor);
        TimelockController(payable(d.timelock)).grantRole(TimelockController.EXECUTOR_ROLE(), address(0));
        TimelockController(payable(d.timelock)).grantRole(TimelockController.CANCELLER_ROLE(), deployer);
        TimelockController(payable(d.timelock)).revokeRole(TimelockController.TIMELOCK_ADMIN_ROLE(), deployer);

        vm.stopBroadcast();

        _log(d);
    }

    function _resolveFeed(address envFeed, uint8 decimals, int256 mockAnswer) internal returns (address) {
        if (envFeed != address(0) && !vm.envOr("USE_MOCK_ORACLES", false)) {
            return envFeed;
        }
        return address(new MockChainlinkAggregator(decimals, mockAnswer));
    }

    function _log(Deployment memory d) internal view {
        console2.log("govToken", d.govToken);
        console2.log("timelock", d.timelock);
        console2.log("governor", d.governor);
        console2.log("treasury", d.treasury);
        console2.log("priceOracle", d.priceOracle);
        console2.log("porOracle", d.porOracle);
        console2.log("factory", d.factory);
        console2.log("assetNft", d.assetNft);
        console2.log("collateralToken", d.collateralToken);
        console2.log("vault", d.vault);
        console2.log("amm", d.amm);
        console2.log("upgradeableToken", d.upgradeableToken);
    }
}
