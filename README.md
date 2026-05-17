# RWA Tokenization Platform

Production-grade capstone for **Blockchain Technologies 2**: ERC-20 collateral-backed tokens, ERC-4626 yield vault, Chainlink price feeds / Proof of Reserve, role-gated issuer minting, OpenZeppelin Governor + Timelock, constant-product AMM, L2 deployment on **Arbitrum Sepolia** (also supports Base / Optimism Sepolia).


## Quick start

```bash
# Fix Foundry if needed: brew install libusb && foundryup
bash scripts/install-deps.sh
cp .env.example .env
forge build
forge test
```

Deploy (Arbitrum Sepolia):

```bash
source .env
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_ARBITRUM_SEPOLIA --broadcast --verify
```

Post-deploy verification:

```bash
export TIMELOCK=0x... GOVERNOR=0x... DEPLOYER=0x...
forge script script/VerifyDeployment.s.sol:VerifyDeployment --rpc-url $RPC_ARBITRUM_SEPOLIA
```

## Architecture

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Issuers    │────▶│ RWACollateralToken│◀───│ ProofOfReserve  │
│ (ISSUER)    │     │  + Factory        │     │ (Chainlink PoR) │
└─────────────┘     └────────┬─────────┘     └─────────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
  ┌─────────────┐    ┌──────────────┐    ┌──────────────┐
  │ RWAYieldVault│    │ ConstantAMM  │    │ Asset NFT    │
  │  (ERC-4626)  │    │  (x·y=k)     │    │  (ERC-721)   │
  └─────────────┘    └──────────────┘    └──────────────┘
                             │
                    ┌────────▼────────┐
                    │ Governor+Timelock │
                    │  (RWAGOV votes)   │
                    └───────────────────┘
```

See `docs/architecture.md`, `docs/audit-report.md`, `docs/gas-report.md`, `docs/coverage.md`.

## Mandatory checklist (Section 3)

| Requirement | Location |
|-------------|----------|
| UUPS V1→V2 | `contracts/upgradeable/` |
| Factory CREATE + CREATE2 | `contracts/factory/RWAAssetFactory.sol` |
| Yul assembly benchmark | `contracts/utils/AssemblyUtils.sol`, `test/unit/Assembly.t.sol` |
| ERC20Votes + Permit gov token | `contracts/tokens/RWAGovernanceToken.sol` |
| ERC-721 certificates | `contracts/tokens/AssetCertificateNFT.sol` |
| ERC-4626 vault | `contracts/vault/RWAYieldVault.sol` |
| AMM 0.3% fee | `contracts/amm/ConstantProductAMM.sol` |
| Chainlink + staleness | `contracts/oracles/` |
| Governor + 2d Timelock | `contracts/governance/`, `script/Deploy.s.sol` |
| Subgraph 4+ entities | `subgraph/` |
| 80+ tests | `test/` |
| Frontend + subgraph read | `frontend/` |
| CI (forge + slither) | `.github/workflows/ci.yml` |

## Design patterns (documented in architecture doc)

1. Factory — asset token deployment  
2. UUPS proxy — upgradeable wrapper  
3. Checks-Effects-Interactions — vault, AMM, treasury  
4. Pull-over-push — `ProtocolTreasury.claimWithdrawal`  
5. Access Control — issuers, pausers, timelock admin  
6. Pausable — collateral + vault  
7. State machine — NFT asset lifecycle  
8. Oracle adapter — `ChainlinkPriceOracle`  
9. Timelock — governance execution  
10. ReentrancyGuard — vault, AMM  

## L2 deployment addresses

> Update after deploy — Arbitrum Sepolia

| Contract | Address |
|----------|---------|
| RWAGovernanceToken | `TBD` |
| TimelockController | `TBD` |
| RWAGovernor | `TBD` |
| RWACollateralToken | `TBD` |
| RWAYieldVault | `TBD` |

## License

MIT
# BlockchainTechnologies2Finalexam
