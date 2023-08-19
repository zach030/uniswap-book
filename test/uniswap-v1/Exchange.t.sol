// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/StdUtils.sol";
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
        token.approve(address(exchange), 1e18);
    }

    function testaddLiquidity() public {
        exchange.addLiquidity{value: 1000 wei}(1000);
        assertEq(lp.balanceOf(address(this)), 1000);
        exchange.addLiquidity{value: 100 wei}(100);
        assertEq(lp.balanceOf(address(this)), 1100);
    }

    function testgetTokenAmount() public {
        exchange.addLiquidity{value: 1000 wei}(1000);
        uint256 tokenBorrow = exchange.getTokenAmount(100);
        assertLe(tokenBorrow, 1000 wei);
    }
    
    function testethToTokenSwap() public {
        exchange.addLiquidity{value :100 wei}(200); 
        vm.startPrank(player);
        vm.deal(player, 15 wei);
        exchange.ethToTokenSwap{value: 10 wei}(0);
        uint256 tokenBalance = token.balanceOf(address(player));
        assertLe(tokenBalance , 20);
        vm.stopPrank();
    }

    function testSwapFee() public {
        exchange.addLiquidity{value: 1000 wei}(1000);
        vm.startPrank(player);
        vm.deal(player, 100 wei);
        // swap 100 wei to token
        exchange.ethToTokenSwap{value: 100 wei}(0);
        uint256 tokenBalance = token.balanceOf(address(player));
        // expect token amount less than 100
        assertLe(tokenBalance, 100);

        // exchange token balance greater than 900
        uint256 exchangeTokenBalance = token.balanceOf(address(exchange));
        assertGe(exchangeTokenBalance, 1000-100);
        vm.stopPrank();       
    }

    function testImplermanentLoss() public{
        // init liquidity: 9 ether + 900 token
        exchange.addLiquidity{value :9 ether}(900); 

        // add liquidity: 1 ether + 100 token = 1*400+100=500u
        address lpUser = makeAddr('lp');
        vm.startPrank(lpUser);
        vm.deal(lpUser, 1 ether);
        deal(address(token), lpUser, 100);
        token.approve(address(exchange), 100);

        exchange.addLiquidity{value :1 ether}(100); 
        // pool: 10 ether + 1000 token => 1 ether = 100 token
        vm.stopPrank();

        console.log("before swap exchange token reserve:", exchange.getReserve());
        console.log("before swap exchange eth reserve:", address(exchange).balance);

        vm.startPrank(player);
        deal(address(token), player, 1000);
        token.approve(address(exchange), 1000);
        exchange.tokenToETHSwap(1000, 1 ether);
        vm.stopPrank();
        // pool: 5 ether + 2000 token => 1 ether = 400 token
        console.log("after swap exchange token reserve:", exchange.getReserve());
        console.log("after swap exchange eth reserve:", address(exchange).balance);

        // lp remove liquidity
        vm.startPrank(lpUser);
        uint256 lpAmount = lp.balanceOf(lpUser);
        (uint256 ethAmount, uint256 tokenAmount) = exchange.removeLiquidity(lpAmount);
        vm.stopPrank();
        console.log("lp token balance:", token.balanceOf(lpUser));
        console.log("lp eth balance:", address(lpUser).balance);    
        // 0.5 ether + 200 token = 400*0.5 + 200 = 400u 
    }
}