#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v forge &>/dev/null; then
  echo "Foundry not found. Install: curl -L https://foundry.paradigm.xyz | bash && foundryup"
  exit 1
fi

forge install foundry-rs/forge-std --no-commit
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-commit
forge install OpenZeppelin/openzeppelin-contracts-upgradeable@v5.0.2 --no-commit

echo "Dependencies installed under lib/"
