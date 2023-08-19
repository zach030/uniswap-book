// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/StdUtils.sol";
import "../../src/uniswap-v1/Factory.sol";
import "../../src/uniswap-v1/Token.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FactoryTest is Test {
    Factory factory;


    function setUp() public {
        factory = new Factory();
    }

    function testcreateExchange() public {
        ERC20 tt = new ERC20("t","tt");
        address pair = factory.createExchange(address(tt));
        assertEq(factory.getExchange(address(tt)), pair);
    }
}