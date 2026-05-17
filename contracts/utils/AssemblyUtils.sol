// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Yul assembly vs pure-Solidity equivalents — benchmarked in tests/gas.
library AssemblyUtils {
  /// @dev Assembly: load slot 0 of `account` (balance in ERC20 layout is slot 0 for OZ ERC20).
  function balanceOfAssembly(address account) internal view returns (uint256 bal) {
    bytes32 slot;
    assembly {
      mstore(0x00, account)
      mstore(0x20, 0)
      slot := keccak256(0x00, 0x40)
      bal := sload(slot)
    }
  }

  /// @dev Pure Solidity equivalent for comparison.
  function balanceOfSolidity(mapping(address => uint256) storage balances, address account)
    internal
    view
    returns (uint256)
  {
    return balances[account];
  }

  /// @dev Assembly multiply with overflow check via revert.
  function mulAsm(uint256 x, uint256 y) internal pure returns (uint256 z) {
    assembly {
      z := mul(x, y)
      if iszero(or(iszero(x), eq(div(z, x), y))) {
        revert(0, 0)
      }
    }
  }

  function mulSolidity(uint256 x, uint256 y) internal pure returns (uint256) {
    return x * y;
  }
}
