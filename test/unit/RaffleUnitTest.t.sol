// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleUnitTest is Test {
    event raffleEntered(address indexed player);
    event RaffleWinnerPicked(address indexed winner);
    address PLAYER1 = makeAddr("player1");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;
    Raffle public raffle;
    HelperConfig public helpConfig;
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    function setUp() external {
        DeployRaffle raffleDeployer = new DeployRaffle();
        (raffle, helpConfig) = raffleDeployer.deployRaffle();
        HelperConfig.NetworkConfig memory config = helpConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;

        vm.deal(PLAYER1, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitialState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testEnterRaffleRevertWhenYouDontPayEnoughForEnteringRaffle()
        public
    {
        // Arrange
        vm.prank(PLAYER1);
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__NeedMoreETHToEnterRaffle.selector); // expectRevert with custom errors returned in raffle contract
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenEntered() public {
        // Arrange
        vm.prank(PLAYER1);

        // Act
        raffle.enterRaffle{value: entranceFee}(); // () => as we do not have any function parameters

        // Assert
        address playerRecorded = raffle.getPlayersAddress(0);
        assert(playerRecorded == PLAYER1);
    }

    // TESTING events and emits which show up in transaction log

    function testEnteringRaffleEmitsPlayerAddress() public {
        // Arrange
        vm.prank(PLAYER1);

        // Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit raffleEntered(PLAYER1);

        // Assert
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDoNotAllowPlayersEnteringRaffleWhileCalculating() public {
        // Arrange
        vm.prank(PLAYER1);
        raffle.enterRaffle{value: entranceFee}();

        // how we can wait and have some time passed for running the performUpkeep
        // conditions for passing checkUpkeep
        // bool timeHaspassed = ((block.timestamp - s_lastTimeStamp) >=
        //     i_intervalRaffleDuration); (How??) using vm.wrap and vm.roll
        // bool raffleIsOpen = s_raffleState == RaffleState.OPEN; (Already in OPEN)
        // bool hasBalance = address(this).balance > 0; (We have funded the money to the PLAYER1)
        // bool hasPlayers = s_rafflePlayers.length > 0; (We have one player added)

        vm.warp(block.timestamp + interval + 1); // it is cheatcode used to simulate time travel by manipulating the blockchain's block timestamp.(in sec's)
        vm.roll(block.number + 1); // changes the block number (here it is saying that this is the second block as we changed the time) BEST PRACTICE
        raffle.performUpkeep("");

        // Act / Assert
        vm.expectRevert(Raffle.Raffle__raffleNotInOpenState.selector);
        // Now lets see if we are allowed to enter the raffle as performUpkeep is called because it sets raffle state to calculating
        vm.prank(PLAYER1);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCheckUpkeepReturnsFalseIfitHasNoBalance() public {
        //Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act 
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(upKeepNeeded == false);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsNotOpen() public {
        // Arrange
        vm.prank(PLAYER1);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        // Act 
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(upKeepNeeded == false);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasNotPassed() public {
        // Arrange
        vm.prank(PLAYER1);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval - 1); // we are warping to just before the interval time has passed
        vm.roll(block.number + 1);

        // Act 
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(upKeepNeeded == false);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
        // Arrange
        vm.prank(PLAYER1);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1); // we are warping to just after the interval time has passed
        vm.roll(block.number + 1);

        // Act 
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(upKeepNeeded == true);
    }
}
