# Gas Optimization Report

Generate benchmarks:

```bash
forge test --gas-report
```

## Assembly vs Solidity (`AssemblyUtils`)

| Operation | Assembly | Solidity |
|-----------|----------|----------|
| `mul` | TBD | TBD |
| `balanceOf` (mapping) | TBD | TBD |

## L1 vs L2 comparison (6+ operations)

| Operation | L1 (est.) | Arbitrum Sepolia |
|-----------|-----------|------------------|
| mint | TBD | TBD |
| vault deposit | TBD | TBD |
| swap | TBD | TBD |
| propose | TBD | TBD |
| vote | TBD | TBD |
| execute | TBD | TBD |
