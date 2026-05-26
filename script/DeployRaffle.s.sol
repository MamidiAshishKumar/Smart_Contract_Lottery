// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {}

    function deployRaffle() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // if we are on local chain -> deploy VRF coordinator mock and get the local config for the local blockchain
        // if we are on sepolia -> call VRF coordinator address for randomness for raffle contract
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            // If subscriptionId is 0, we need to create a new subscription and fund it
            // This part can be implemented to create a subscription on the VRF Coordinator Mock and fund it with fake LINK tokens
            CreateSubscription createSubscriptionScript = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createSubscriptionScript.createSubscription(config.vrfCoordinator); // why createSubscription with config.vrfCoordinator? Because we need to interact with the VRF Coordinator Mock contract to create a subscription, and we need the address of the VRF Coordinator Mock contract to do that. The config.vrfCoordinator provides us with the address of the VRF Coordinator Mock contract that we need to interact with to create a subscription. 
            // Update the subscriptionId in the helperConfig with the new subscription ID

            // Fund the subscription with fake LINK tokens (this can be implemented to interact with the VRF Coordinator Mock contract to fund the subscription with fake LINK tokens)


        }

        vm.startBroadcast();
        Raffle raffleContract = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        return (raffleContract, helperConfig);
    }
}
