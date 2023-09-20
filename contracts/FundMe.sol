// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

contract FundMe {
    using PriceConverter for uint256;

    uint256 public minUSD = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;

    constructor() {
        owner = msg.sender; // --> owner will be the person who called the constructor, i.e deployer of the contract
    }

    function fund() public payable {
        // Want to be able to set a minimum fund amount in USD  
        // require (getConversionRate(msg.value) >= minUSD, "Didn't send enough ethereum!!"); //msg.value --> 18 decimal places
        
        require(msg.value.getConversionRate() >= minUSD, "Didn't send enought Ethereum!!");
        
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);

        // transfer, send and call method

        //transfer
        // payable(msg.sender).transfer(address(this).balance); // --> Capped at 2300 gas and throws an error if exceeded

        //send
        // bool sendSuccess =  payable(msg.sender).send(address(this).balance); // --> Capped at 2300 gas and returns a boolean
        // require(sendSuccess, "Send failed");

        //call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}(""); // --> Forwads all gas and returns a boolean --> recommended way to send ETH
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Sender is not owner");
        _; // --> rest of the code wherever this modifier is used
    }

}
