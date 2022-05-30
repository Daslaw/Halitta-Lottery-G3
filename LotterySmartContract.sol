// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract LotterySmartContract is VRFConsumerBaseV2{
    receive() external payable{
        register();
    }
    fallback() external payable{
        register();
    }
    address internal owner;
    address payable[] public players;
    address public winner;
    uint public balances;
    uint public round;
    uint public numberOfPlayers;
    uint public amount = 0.02 ether;

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not the owner");
        _;
    }
    modifier state() {
        require(  inProgress == true, "sorry, you can't play at the moment");
        _;
    }
    bool public inProgress = false;
    mapping (uint => address) public WinnersOfEachRounds;
    mapping (uint => uint) public participantsInEachRounds;
     VRFCoordinatorV2Interface COORDINATOR;


  uint64 s_subscriptionId;
  address constant vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
  bytes32 constant keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
  uint32 constant callbackGasLimit = 100000;
  uint16 constant requestConfirmations = 3;
  uint32 numWords =  2;

  uint256[] public s_randomWords;
  uint256 public s_requestId;

    constructor() VRFConsumerBaseV2(vrfCoordinator){
        owner =msg.sender;
         s_subscriptionId = 5114;
        round = 1;
          COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    function startLottery() public onlyOwner{
        require(  inProgress  == false, "lottery is already in progress");
          inProgress = true;
    }
    function register() public payable state {
        require(msg.value == amount, "required amount not met");
        balances = address(this).balance;
        players.push(payable(msg.sender));
        numberOfPlayers = players.length;
    }
        function requestRandomWords() external onlyOwner state{
            // Will revert if subscription is not set and funded.
            s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
            );
        }
        
        function fulfillRandomWords(
            uint256, /* requestId */
            uint256[] memory randomWords
        ) internal override {
            s_randomWords = randomWords;
        }

    function selectWinner(uint value) public onlyOwner state {
        uint index =  s_randomWords[value]% players.length;
        winner =players[index];
        inProgress = false;
    }

    function creditWinner() public payable onlyOwner{
        payable(winner).transfer(address(this).balance);
        balances = 0;
        WinnersOfEachRounds[round] = winner;
        participantsInEachRounds[round] = numberOfPlayers;
        players = new address payable[](0);
        numberOfPlayers =players.length;
        round++;
        winner;
    }
}