# Architecture & Design Document

> Capstone minimum 6 pages — expand diagrams and ADRs before submission.

## 1. System context (C4 L1)

External actors: **Issuers**, **Investors**, **DAO voters**, **Chainlink oracles**, **The Graph**, **L2 sequencer**.

## 2. Container diagram

- **On-chain**: Collateral tokens, vault, AMM, Governor, Timelock, Treasury, NFT registry, Factory, UUPS proxy token.
- **Off-chain**: Issuer custody / reserve attestations, subgraph indexer, React dApp.

## 3. Critical flows (sequence diagrams to add)

1. **Issuer mint**: PoR check → `mint()` → subgraph `MintEvent`
2. **Vault deposit**: approve → `deposit()` → shares
3. **Governance**: `propose` → `castVote` → `queue` → `execute` via Timelock

## 4. Storage layout (upgradeable)

`RWATokenV1`: ERC20 + AccessControl + UUPS slots (OZ standard).  
`RWATokenV2`: appends `maxSupply`, `version` — no reordering of V1 slots.

## 5. Trust assumptions

- Timelock is sole admin after deploy (`Deploy.s.sol` revokes deployer).
- Issuers cannot mint without sufficient PoR feed.
- Oracle staleness bounded by `maxStaleness`.

## 6. ADRs (template)

| ID | Decision | Rationale |
|----|----------|-----------|
| ADR-001 | Foundry over Hardhat | Fuzz/invariant/coverage native |
| ADR-002 | Arbitrum Sepolia primary L2 | Low fees, Chainlink feeds available |
| ADR-003 | AMM alongside RWA | Satisfies DeFi primitive + secondary liquidity |
