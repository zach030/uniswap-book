// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/uniswap-v1/Exchange.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ExchangeTest is Test {
    Exchange public exchange;
    Uni token;

    function setUp() public {
        token = new Uni("uni", "u");
        exchange = new Exchange(address(token));
    }

    function testaddLiquidity() public {
        token.approve(address(exchange), 1e17);
        exchange.addLiquidity{value: 1 ether}(1e17);
    }

}

contract Uni is ERC20{
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1e18);
    }
}