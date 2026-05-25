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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

// preferred way to annotate the code

// type this /** */ - it is called natspec documntation

/**
 * @title A Sample Raffle Contract
 * @author Ashish Kumar
 * @notice This contract is for creating a sample raffle contract
 * @dev Implements ChainLink  VRFv2.5
 */

// if the inherited contract is having constructer then we need to include the inherited constructer in this contract constucter below (Inheriting - VRFConsumerBaseV2Plus and add the cooridinator address to the constructer)
// constructer of VRFConsumerBaseV2Plus - constructor(address _vrfCoordinator)

contract Raffle is VRFConsumerBaseV2Plus {
    uint256 private immutable i_entranceFee; // immutable variable
    error Raffle__NeedMoreETHToEnterRaffle(); // custom errors - because they are gas efficient instead of require as it needs to store stings for require statement
    error Raffle__TranferFailedToWinner();
    error Raffle__raffleNotInOpenState();
    error Raffle__checkUpKeepNotTrue(
        uint256 balance,
        uint256 length,
        uint256 state
    ); // custom erros and passing arguments when we are reverted with custom error we can understand more with the arguments

    // good naming convention for errors is contractname__nameofthecustomerror

    // we can use custom errors in require itself
    // require(msg.value >= i_entranceFee, NeedMoreETHToEnterRaffle());

    // Events - (BluePrint) this is a declaration, you define what data you want to log.
    // Parameters - it accepts upto three indexed parameters and non-indexed parameters

    event raffleEntered(address indexed player);
    event RaffleWinnerPicked(address indexed winner);

    // type declarations
    // enum which is referenced below
    enum RaffleState {
        OPEN, // if it is OPEN it is "0"
        CALCULATING // if it CALCULATING it is "1"
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3; // number of block confirmations with random number before sending the random number
    uint32 private constant NUM_WORDS = 1; // The number of random numbers to request.
    bool private constant enableNativePayment = false;
    address payable[] private s_rafflePlayers; // address dynamic array as payable because we want to send the money to players
    uint256 private immutable i_intervalRaffleDuration; //  The duration of each lottery/Raffle round
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionID;
    uint32 private immutable i_callbackGasLimit;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState; // for tracking raffle state because we are not going to start the raffle if it is in CALCULATING state

    constructor(
        uint256 entranceFee,
        uint256 intervalRaffle,
        address _vrfCoordinator, // pass _vrfCoordinator address next to the VRFConsumerBaseV2Plus so it will be passed to VRFConsumerBaseV2Plus constructer
        bytes32 gasLane, // Vrf gas lane keyhash
        uint256 subscriptionID, // Subscription ID for the Vrf chainLink
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_intervalRaffleDuration = intervalRaffle;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionID = subscriptionID;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Hey, Not Enough ETH sent to enter raffle!") we use custom errors instead of this down below

        if (msg.value < i_entranceFee) {
            revert Raffle__NeedMoreETHToEnterRaffle();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__raffleNotInOpenState();
        }

        // payable - A keyword and modifier used to explicitly declare that a function or address is allowed to receive, hold, or transfer Ether (ETH) so that it can call .send() or .tranfer() if the address is payable

        s_rafflePlayers.push(payable(msg.sender));

        // Events and Emits
        // Makes migration easier
        // Makes front end "indexing" easier

        // emit - This is the actual command tht executes the log, it writes the data to the blockchain logs

        emit raffleEntered(msg.sender);
    }

    // when should the winner be picked
    /**
     * @dev This is the finction that chainlink nodes will call to see if the raffle lottery is ready to be have a winner picked
     * The following should be true in order for upkeepNeeded to be true:
     * 1) The time interval has passed between raffle runs
     * 2) the lottery is in open state
     * 3) the contract has ETH tokens
     * 4) subscription should have link/sepolia tokens
     * @return upkeepNeeded - true if its time to restart the lottery
     * @return - ignored
     */
    function checkUpkeep(
        bytes memory /* checkdata */
    )
        public
        view
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */ // upkeepNeeded should be true if the winner is picked
        )
    {
        bool timeHaspassed = ((block.timestamp - s_lastTimeStamp) >=
            i_intervalRaffleDuration);
        bool raffleIsOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_rafflePlayers.length > 0;
        upkeepNeeded =
            timeHaspassed &&
            raffleIsOpen &&
            hasBalance &&
            hasPlayers;
        return (upkeepNeeded, "");
    }

    // This function should be called automactically - chainlink automation (time based) - where we have checkUpkeep and performUpkeep functions
    function performUpkeep(bytes calldata /* performData */) external {
        // 1. Get a random number
        // 2. Use Random number to pick a player
        // 3. Be automactically called after some given time to pick a winner

        // check to see if enough time has passed
        // everytime a winner is picked we want to update s_lastTimeStamp

        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__checkUpKeepNotTrue(
                address(this).balance,
                s_rafflePlayers.length,
                uint256(s_raffleState)
            ); // custom error and revert with arguments
        }
        // if enough time has happened we need to get an random number from Chainlink

        // To get the random number from chainlink VRF 2.5
        // pickwinner() will request RNG (Random number generator)
        // chainlink oracle nodes will get the RNG and Vrf Coordinator will call callback function after generating the random number

        // consumer address - 0x7781d8d8d0f1fb2594312424a94f723d15be37da
        // vrf coordinator address - 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B

        /**
         * @dev struct is defined in VRFV2PlusClient
         */

        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionID,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
                )
            });

        // uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        s_vrfCoordinator.requestRandomWords(request);
    }

    // CEI Method while writing functions - Checks, Effects and Interactions
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        // Checks
        // Conditionals (require and if/else statements which will check for somthing before we go into CORE logic of the function)

        // we will use module function to choose a player from the random number
        // lets say random number = 675757585858598598598 and s_rafflePlayers array length is 10
        // 675757585858598598598 % 10 = 8 so 8th player will be the winner

        // Effects (Changing the internal state variables)
        uint256 indexOfWinner = randomWords[0] % s_rafflePlayers.length;
        address payable recentRaffleWinner = s_rafflePlayers[indexOfWinner];
        s_recentWinner = recentRaffleWinner;
        s_rafflePlayers = new address payable[](0); // after choosing the winner we need to blank out the players array
        s_lastTimeStamp = block.timestamp; // we have set the timestamp to newly created block on executing the function
        s_raffleState = RaffleState.OPEN;
        emit RaffleWinnerPicked(s_recentWinner);

        // Interactions (External Contract Interactions)
        (bool success, ) = recentRaffleWinner.call{
            value: address(this).balance
        }(""); // give the entire balance of this contract to the winner
        if (!success) {
            revert Raffle__TranferFailedToWinner();
        }
    } // we need to have fulfillRandomWords functions defined because in VRFConsumerBaseV2Plus this is undefined

    // getter functions
    function getentranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayersAddress(
        uint256 IndexOfPlayer
    ) external view returns (address) {
        return s_rafflePlayers[IndexOfPlayer];
    }
}
