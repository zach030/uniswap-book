// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/uniswap-v1/Exchange.sol";
import "../../src/uniswap-v1/Token.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ExchangeTest is Test {
    Exchange public exchange;
    Token token;

    function setUp() public {
        token = new Token("uni", "u", 1e18);
        exchange = new Exchange(address(token));
    }

    function testaddLiquidity() public {
        token.approve(address(exchange), 1000);
        exchange.addLiquidity{value: 1 ether}(1000);
    }

    function testgetPrice() public {
        token.approve(address(exchange), 1e18);
        exchange.addLiquidity{value: 1 ether}(1e18);
        uint256 tokenReserve = exchange.getReserve();
        uint256 tokenPrice = exchange.getPrice(address(exchange).balance, tokenReserve);
        assertEq(tokenPrice, 1);
    }

}