// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

//initializes a NotOwner error. This is used in the onlyOwner modifier
error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;
    AggregatorV3Interface private s_priceFeed;

    //i_owner should be immutable because it isn't assigned a value until the contract is deployed, vs when it's compiled.
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18; // $5

    //initializes i_owner and priceFeed during the contract deployment
    //Question: Should I make s_priceFeed immutable? What would the considerations be here?
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    //a function that can be called by an external account (smart contract or wallet
    //requires a minimum of $5 to be sent (as converted into USD)
    //adds the funded value to the s_addressToAmountFunded mapping
    //adds the funders address to the s_funders array
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    //returns the version of the priceFeed
    //.version() is defined in Chainlink contracts in the lib
    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    //a modifier is a special type of function, like the constructor
    //can be attached to functions after the visibility to specify an action before or after the function starts
    //i.e., by adding onlyOwner() to a function, the function will only run if the caller is the owner
    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    //only the owner can withdraw
    //for loop resets s_funders after removing all funders
    //Question: Is the for loop needed if you can just reset the array with s_funders = new address[](0)?
    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        //.call returns two values, the first is a boolean that indicates if the call was successful
        //second is the bytes data that you send in ("")
        //payable wrapper is needed for msg.sender & .call specifies a transfer back to the function caller
        //value: address(this).balance specifies the amount to send back, which is the amount in the contract

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    //same as withdraw function above, but sets fundersLength = s_funders.length before the for loop
    //This stops the contract from having to access storage to know s_funders.length in every for loop iteration
    //This saves gas, as it now just has to access s_funders.length once from storage, and then it reads fundersLength from memory.
    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;

        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    //external is good when you're not trying to access a function within the same contract
    //fallback functions are useful when an account(wallet or contract) sends ETH w/ data but it doesn't match existing functions
    fallback() external payable {
        fund();
    }

    //receive functions are useful when an account(wallet or contract) sends ETH w/o data but it doesn't match existing functions
    receive() external payable {
        fund();
    }

    //view functions are read-only functions that don't modify the state of the contract
    //takes in an address to return the amount funded by that address;
    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    //takes in an index # and returns an address that corresponds to the s_funders[#]
    function getFunders(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    //returns the address of the owner.
    function getOwner() external view returns (address) {
        return i_owner;
    }
}
