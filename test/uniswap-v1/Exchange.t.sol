// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/uniswap-v1/Exchange.sol";
import "../../src/uniswap-v1/Token.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ExchangeTest is Test {
    Exchange public exchange;
    ERC20 public lp;
    Token token;
    address player = makeAddr('player');
    receive() external payable{}
    function setUp() public {
        token = new Token("uni", "u", 1e18);
        exchange = new Exchange(address(token));
        lp = ERC20(address(exchange));
    }

    function testaddLiquidity() public {
        token.approve(address(exchange), 2000);
        exchange.addLiquidity{value: 1000 wei}(1000);
        assertEq(lp.balanceOf(address(this)), 1000);
        exchange.addLiquidity{value: 100 wei}(100);
        assertEq(lp.balanceOf(address(this)), 1100);
    }

    function testgetTokenAmount() public {
        token.approve(address(exchange), 1000);
        exchange.addLiquidity{value: 1000 wei}(1000);
        uint256 tokenBorrow = exchange.getTokenAmount(100);
        assertLe(tokenBorrow, 1000 wei);
    }
    
    function testethToTokenSwap() public {
        token.approve(address(exchange), 1000);
        exchange.addLiquidity{value :100 wei}(200); 
        vm.startPrank(player);
        vm.deal(player, 15 wei);
        exchange.ethToTokenSwap{value: 10 wei}(0);
        uint256 tokenBalance = token.balanceOf(address(player));
        assertLe(tokenBalance , 20);
        vm.stopPrank();
    }

    function testImplermanentLoss() public{
        token.approve(address(exchange), 1000);
        exchange.addLiquidity{value :100 wei}(200); 

        vm.startPrank(player);
        vm.deal(player, 15 wei);
        
        exchange.ethToTokenSwap{value: 10 wei}(0);
        uint256 tokenBalance = token.balanceOf(address(player));
        assertLe(tokenBalance , 20);
        
        vm.stopPrank();
        
        uint256 ethAmount;
        uint256 tokenAmount;
        (ethAmount, tokenAmount) = exchange.removeLiquidity(100);
        assertGe(ethAmount, 100 wei);
        assertLe(tokenAmount, 200);
    }
}