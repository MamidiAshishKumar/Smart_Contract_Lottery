// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "../lib/chainlink-evm/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol"; // Mock for VRFCoordinator
import {LinkToken} from "../test/mocks/LinkToken.sol"; // Mock for LINK token

abstract contract ConstantVariablesAndErrors {
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 LOCAL_CHAIN_ID = 31337;
    error HelperConfig__NoNetworkConfigFound();

    // Vrf Mock values
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15; // 0.004 ETH per LINK
}

contract HelperConfig is Script, ConstantVariablesAndErrors {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address link;
    }

    NetworkConfig public activeNetworkConfig;
    mapping(uint256 chainID => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig(); // if the chain ID is Sepolia, use the Sepolia configuration
    }

    function getNetworkConfigByChainID(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            // getOrCreateAnvilEthConfig() can be implemented to set up a local VRF Coordinator and return the configuration for local testing
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__NoNetworkConfigFound();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getNetworkConfigByChainID(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether, // 1e16
                interval: 30, // 30 seconds
                vrfCoordinator: 0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE, // Sepolia VRF Coordinator
                gasLane: 0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71, // Sepolia Gas Lane for 30 Gwei keyHash
                callbackGasLimit: 500000, // 500,000 gas
                subscriptionId: 0, // To be set after creating a subscription
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789 // for Sepolia, the LINK token address is 0x779877A7B0D9E8603169DdbD7836e478b4624789 which is the address of the LINK token on Sepolia, and it is used for funding the subscription with LINK tokens when we are on the Sepolia network. This address is important because it allows us to interact with the LINK token contract to transfer LINK tokens to our subscription, which is necessary for paying for VRF requests.
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // This function can be implemented to set up a local VRF Coordinator and return the configuration for local testing
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }

        // Deploy mocks if we want to run on the local
        // we have impoted the VRF coordinator mock above

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UNIT_LINK
        );
        LinkToken linkTokenMock = new LinkToken();
        // MOCK_BASE_FEE - On a live network, Chainlink charges a specific amount of LINK (or native gas like ETH/BNB depending on the version and network) just to kickstart the request.
        // MOCK_GAS_PRICE_LINK - gas to broadcast a transaction that calls your fulfillRandomWords function
        // MOCK_WEI_PER_UNIT_LINK - In a real network, Chainlink nodes need to convert gas costs (which are paid in the network's native token like ETH) into the amount of LINK it will charge your subscription.
        vm.stopBroadcast();

        activeNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, // 30 seconds
            vrfCoordinator: address(vrfCoordinatorMock), // Sepolia VRF Coordinator
            gasLane: 0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71, // Sepolia Gas Lane for 30 Gwei keyHash, does not matter for mock
            callbackGasLimit: 500000, // 500,000 gas
            subscriptionId: 0, // To be set after creating a subscription
            link: address(linkTokenMock) // for local testing, we can set the LINK token address to the mock address
        });

        return activeNetworkConfig;
    }
}
