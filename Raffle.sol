// Layout of Contract:
// license
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.5.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

// preferred way to annotate the code

// type this /** */ - it is called natspec documntation

/**
 * @title A Sample Raffle Contract
 * @author Ashish Kumar
 * @notice This contract is for creating a sample raffle contract
 * @dev Implements ChainLink  VRFv2.5
 */

contract Raffle {
    uint256 private immutable i_entranceFee; // immutable variable
    error Raffle__NeedMoreETHToEnterRaffle(); // custom errors - because they are gas efficient instead of require as it needs to store stings for require statement

    // good naming convention is contractname__nameofthecustomerror

    // we can use custom errors in require itself
    // require(msg.value >= i_entranceFee, NeedMoreETHToEnterRaffle());

    // Events - (BluePrint) this is a declaration, you define what data you want to log.
    // Parameters - it accepts upto three indexed parameters and non-indexed parameters

    event raffleEntered(address indexed player);

    address payable[] private s_rafflePlayers; // address dynamic array as payable because we want to send the money to players
    uint256 private immutable i_intervalRaffleDuration; //  The duration of each lottery/Raffle round
    uint256 private s_lastTimeStamp;

    constructor(uint256 entranceFee, uint256 intervalRaffle) {
        i_entranceFee = entranceFee;
        intervalRaffleDuration = intervalRaffle;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Hey, Not Enough ETH sent to enter raffle!") we use custom errors instead of this down below

        if (msg.value < i_entranceFee) {
            revert NeedMoreETHToEnterRaffle();
        }

        // payable - A keyword and modifier used to explicitly declare that a function or address is allowed to receive, hold, or transfer Ether (ETH) so that it can call .send() or .tranfer() if the address is payable

        s_rafflePlayers.push(payable(msg.sender));

        // Events and Emits
        // Makes migration easier
        // Makes front end "indexing" easier

        // emit - This is the actual command tht executes the log, it writes the data to the blockchain logs

        emit raffleEntered(msg.sender);
    }

    function pickWinner() external {
        // 1. Get a random number
        // 2. Use Random number to pick a player
        // 3. Be automactically called after some given time to pick a winner

        // check to see if enough time has passed
        // everytime a winner is picked we want to update s_lastTimeStamp
        if ((block.timestamp - s_lastTimeStamp) < i_intervalRaffleDuration) {
            revert(); // we will add custom error
        }
        // if enough time has happened we need to get an random number from Chainlink

        // consumer address - 0x7781d8d8d0f1fb2594312424a94f723d15be37da
        // vrf coordinator address - 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B

        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
                )
            })
        );
    }

    // getter functions
    function getentranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
