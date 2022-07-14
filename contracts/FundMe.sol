// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    // IMPORTANT LINE FOR OVERFLOW CHECKER
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    // constructing the smart contract
    // immediately executed as soon as the smart contract is deployed
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUSD = 10 * 10 ** 18;
        // if(msg.value < minimumUSD){revert?}
        // new syntax (at the top is a more pythonic def):
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns(uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256) {
        // (uint80 ,
        //  int256 answer,
        //  uint256 startedAt,
        //  uint256 updatedAt,
        //  uint80 answeredInRound)
        // = priceFeed.latestRoundData();
        // REFACTORED BY OMITTING NON-IMPORTANT VARIABLES IN CALL:
        (,int256 answer,,,) = priceFeed.latestRoundData();

        // TYPECASTING: WRAPPING INTO NEW TYPE
        return uint256(answer * 10000000000);
    }

    // Function to convert any amount of asset (USD, in this example) from eth to that amount of asset
    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUSD;
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 10 * 10 ** 18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10 ** 18;
        return (minimumUSD * precision) / price;
    }
    

    // first modifier to verify the own owner the sender
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function withdraw() payable onlyOwner public {
        // only want the contract owner to use this function:
        // require(msg.sender == owner);
        // very special line of code, i.e.: 'this' means the smart contract it is in
        // 'address(this).balance' uses the balance of this smart contract's address
        msg.sender.transfer(address(this).balance);
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            // SET AMOUNT OF FUNDER WALLET TO 0
            addressToAmountFunded[funder] = 0;
        }
        // MAKE NEW LIST OF FUNDERS ONCE WITHDRAWN
        funders = new address[](0);
    }
}