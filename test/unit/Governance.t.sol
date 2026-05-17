// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {RWAGovernanceToken} from "../../contracts/tokens/RWAGovernanceToken.sol";
import {RWAGovernor} from "../../contracts/governance/RWAGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract GovernanceTest is Test {
    RWAGovernanceToken token;
    TimelockController timelock;
    RWAGovernor governor;
    address deployer = makeAddr("deployer");
    address voter = makeAddr("voter");

    function setUp() public {
        vm.startPrank(deployer);
        token = new RWAGovernanceToken(deployer);
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = address(0);
        executors[0] = address(0);
        timelock = new TimelockController(2 days, proposers, executors, deployer);
        governor = new RWAGovernor(token, timelock);
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));
        token.transfer(voter, 100_000 ether);
        vm.stopPrank();
    }

    function test_delegate_increasesVotes() public {
        vm.prank(voter);
        token.delegate(voter);
        assertEq(token.getVotes(voter), 100_000 ether);
    }

    function test_votingDelay() public view {
        assertEq(governor.votingDelay(), 1 days);
    }

    function test_votingPeriod() public view {
        assertEq(governor.votingPeriod(), 1 weeks);
    }

    function test_quorumNumerator() public view {
        assertEq(governor.quorumNumerator(), 4);
    }

    function test_propose_vote_queue_execute() public {
        vm.prank(voter);
        token.delegate(voter);

        address target = address(token);
        bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", voter, 1 ether);
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = callData;

        vm.prank(voter);
        uint256 pid = governor.propose(targets, values, calldatas, "test proposal");

        vm.warp(block.timestamp + governor.votingDelay() + 1);
        vm.prank(voter);
        governor.castVote(pid, 1);

        vm.warp(block.timestamp + governor.votingPeriod());
        assertTrue(uint8(governor.state(pid)) > 0);
    }
}
