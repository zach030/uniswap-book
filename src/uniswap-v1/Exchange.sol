// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IFactory} from "./Interface.sol";

contract Exchange {
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    address public token;
    IFactory public factory;

    constructor() {
        
    }

    function setup(address tokenAddr) public{
        require(address(factory)==address(0) && token==address(0), "");
        factory = IFactory(msg.sender);
        token = tokenAddr;
        name = 0x556e697377617020563100000000000000000000000000000000000000000000;
        symbol = 0x554e492d56310000000000000000000000000000000000000000000000000000;
        decimals = 18;
    }
}