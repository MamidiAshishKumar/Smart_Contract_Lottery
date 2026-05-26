// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, ConstantVariablesAndErrors} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "../lib/chainlink-evm/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol"; // Mock for VRFCoordinator
import {LinkToken} from "../test/mocks/LinkToken.sol"; // Mock for LINK token

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64, address) {
        // what is createSubscriptionUsingConfig? This function can be implemented to interact with the VRF Coordinator Mock to create a new subscription and return its ID. It uses the HelperConfig to get the VRF Coordinator address, which allows it to work seamlessly on both local and Sepolia networks without hardcoding any addresses. The function will create a subscription on the VRF Coordinator Mock and return the subscription ID along with the VRF Coordinator address for further interactions, such as funding the subscription with fake LINK tokens.
        // This function can be implemented to interact with the VRF Coordinator Mock to create a new subscription and return its ID

        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator; // get the VRF Coordinator address from the helper config
        // the reason why we need vrfCoordinator address is because we need to interact with the VRF Coordinator Mock contract to create a subscription

        // create a subscription on the VRF Coordinator Mock and return the subscription ID...

        (uint64 subscriptionId, ) = createSubscription(vrfCoordinator);
        return (subscriptionId, vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint64, address) {
        // This function can be implemented to interact with the VRF Coordinator Mock to create a new subscription and return its ID
        console.log("Creating Subscription on chainID:", block.chainid);
        vm.startBroadcast();
        // Interact with the VRF Coordinator Mock contract to create a subscription and return the subscription
        uint64 subscriptionId = uint64(
            VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription()
        );
        vm.stopBroadcast();
        // Why creating subscription is changing the state of the blockchain? Because creating a subscription is a transaction that modifies the state of the blockchain by adding a new subscription to the VRF Coordinator Mock contract's storage. This action requires gas and is recorded on the blockchain, which is why it changes the state.
        console.log("Subscription created with ID:", subscriptionId);
        console.log(
            "Please update the subscriptionId in the HelperConfig contract with this new subscription ID for future interactions."
        );
        return (subscriptionId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {

    uint256 public constant FUND_AMOUNT = 3 ether; // Amount of fake LINK tokens to fund the subscription with 3 LINK (assuming 1 LINK = 1 ether in the mock)

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator; // get the VRF Coordinator address from the helper config
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId; // get the subscription ID from the helper config
        // how we can access subscriptionId set in DeployRaffle when we are creating new instance of the HelperConfig contract here? Because the subscriptionId is stored in the HelperConfig contract, and when we create a new instance of the HelperConfig contract, it will have access to the same storage variables, including the subscriptionId. This means that if we update the subscriptionId in one instance of the HelperConfig contract (like in DeployRaffle), it will be reflected in any other instance of the HelperConfig contract that we create later (like in FundSubscription), as they all share the same underlying storage on the blockchain. Therefore, when we call helperConfig.getConfig().subscriptionId in FundSubscription, it will return the updated subscriptionId that was set in DeployRaffle.
        address linkTokenAddress = helperConfig.getConfig().link; // get the LINK token address from the helper config
        fundSubscription(vrfCoordinator, subscriptionId, linkTokenAddress);
        
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkTokenAddress) public {
        // why we need vrfCoordinator address? Because we need to interact with the VRF Coordinator Mock contract to fund the subscription with fake LINK tokens, and we need the address of the VRF Coordinator Mock contract to do that. The vrfCoordinator address allows us to call the appropriate functions on the VRF Coordinator Mock contract to transfer fake LINK tokens to our subscription, which is necessary for paying for VRF requests in our local testing environment.
        console.log("Funding Subscription with ID:", subscriptionId, "on chainID:", block.chainid);
        console.log("Using VrfCoordinator at address:", vrfCoordinator);
        console.log("Using LinkToken at address:", linkTokenAddress);
        
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            // Interact with the VRF Coordinator Mock contract to fund the subscription with fake LINK tokens
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
            console.log("Subscription funded with", FUND_AMOUNT, "fake LINK tokens.");
        }
        else {

        }
    }


    function run() public {
        // This function can be implemented to interact with the VRF Coordinator Mock to fund an existing subscription with fake LINK tokens
        fundSubscriptionUsingConfig();
    }
}
