# RWA Protocol Subgraph

## Entities (4+)

- `Asset`, `MintEvent`, `BurnEvent`, `VaultDeposit`, `GovernanceProposal`

## Example GraphQL queries (5)

```graphql
query Assets { assets { id assetId totalMinted } }
query Mints($asset: ID!) { mintEvents(where: { asset: $asset }) { amount to } }
query Burns { burnEvents(first: 20, orderBy: timestamp, orderDirection: desc) { amount from } }
query VaultDeposits { vaultDeposits { user assets shares } }
query Proposals { governanceProposals { id state forVotes againstVotes } }
```

Deploy after `forge build` with contract address substituted in `subgraph.yaml`.
