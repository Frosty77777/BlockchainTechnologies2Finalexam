// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ProtocolTreasury} from "../../contracts/treasury/ProtocolTreasury.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";

contract TreasuryInvariantTest is Test {
    ProtocolTreasury treasury;
    MockERC20 token;

    function setUp() public {
        treasury = new ProtocolTreasury(makeAddr("tl"));
        token = new MockERC20("T", "T", 18);
    }

    function invariant_balanceCoversPending() public {
        address ben = makeAddr("ben");
        uint256 pending = treasury.pendingWithdrawals(address(token), ben);
        assertLe(pending, token.balanceOf(address(treasury)));
    }
}
