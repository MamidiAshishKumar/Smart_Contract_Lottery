// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

abstract contract ConstantVariablesAndErrors {
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 LOCAL_CHAIN_ID = 31337;
    error HelperConfig__NoNetworkConfigFound();
}

contract HelperConfig is Script, ConstantVariables {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
    }

    NetworkConfig public activeNetworkConfig;
    mapping(uint256 chainID => NetworkConfig) public networkConfigs;
    constructor() {
       networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig(); // if the chain ID is Sepolia, use the Sepolia configuration
    }

    function getNetworkConfig(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainid].vrfCoordinator != address(0)) {
            return networkConfigs[chainid];
        } elseif (chainid == LOCAL_CHAIN_ID) {
            // getOrCreateAnvilEthConfig() can be implemented to set up a local VRF Coordinator and return the configuration for local testing
        } else {
            revert HelperConfig__NoNetworkConfigFound();
        }
    }

    function getSepoliaEthConfig() returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether, // 1e16
            interval: 30, // 30 seconds
            vrfCoordinator: 0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE, // Sepolia VRF Coordinator
            gasLane: 0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71, // Sepolia Gas Lane for 30 Gwei keyHash
            callbackGasLimit: 500000, // 500,000 gas
            subscriptionId: 0 // To be set after creating a subscription
        })
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // This function can be implemented to set up a local VRF Coordinator and return the configuration for local testing
        if(activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }
    }


}