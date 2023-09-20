// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; 
    // By making the non-changing variables constant, we can reduce the total gas cost for the transaction  
    // Constant values are assigned at compile time
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public immutable i_owner;

    constructor() {
        i_owner = msg.sender; 
        // owner will be the person who called the constructor, i.e deployer of the contract
        // Making the variable as immutable means it can only be assigned a value once in runtime
        // Reduces gas consumption
    }

    function fund() public payable {
        // Want to be able to set a minimum fund amount in USD  
        // require (getConversionRate(msg.value) >= minUSD, "Didn't send enough ethereum!!"); //msg.value --> 18 decimal places
        
        require(msg.value.getConversionRate() >= MINIMUM_USD, "Didn't send enought Ethereum!!");
        
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
        // require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {revert NotOwner();} // Using custom errors makes it gas efficient
        _; // --> rest of the code wherever this modifier is used
    }

    // What happens when people send ETH without calling the fund function
    
    // receive is a special function that gets called whenever ETH is being sent without data 
    receive() external payable { 
        fund();
    }

    // fallback is a special function that gets called whenever ETH is being sent along with some data
    fallback() external payable {
        fund();
    }

    // But calling the fund function will cost less gas compared to using the recieve or fund functions
}
