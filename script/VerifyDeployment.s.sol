// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {RWAGovernor} from "../contracts/governance/RWAGovernor.sol";

/// @notice Post-deploy verification — run after Deploy.s.sol on testnet.
contract VerifyDeployment is Script {
    function run() external view {
        address timelock = vm.envAddress("TIMELOCK");
        address governor = vm.envAddress("GOVERNOR");
        address deployer = vm.envAddress("DEPLOYER");

        TimelockController tl = TimelockController(payable(timelock));
        RWAGovernor gov = RWAGovernor(governor);

        require(tl.getMinDelay() == 2 days, "timelock delay mismatch");
        require(tl.hasRole(tl.PROPOSER_ROLE(), governor), "governor not proposer");
        require(!tl.hasRole(tl.TIMELOCK_ADMIN_ROLE(), deployer), "deployer still timelock admin");

        require(gov.votingDelay() == 1 days, "voting delay");
        require(gov.votingPeriod() == 1 weeks, "voting period");
        require(gov.quorumNumerator() == 4, "quorum fraction");

        console2.log("Verification passed");
    }
}
