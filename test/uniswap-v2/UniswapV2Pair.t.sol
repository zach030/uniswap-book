// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./mocks/ERC20Mintable.sol";
import "../../src/UniswapV2Pair.sol";

contract UniswapV2PairTest is Test {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniswapV2Pair pair;
    address lp = makeAddr("lp");

    function setUp() public{
        token0 = new ERC20Mintable("Token0","T0");
        token1 = new ERC20Mintable("Token1","T1");
        pair = new UniswapV2Pair(address(token0), address(token1));
        
        vm.startPrank(lp);
        token0.mint(10 ether, lp);
        token1.mint(10 ether, lp);
        vm.stopPrank();
    }

    function testInitialMint() public {
        vm.startPrank(lp);
        token0.transfer(address(pair),1 ether);
        token1.transfer(address(pair),1 ether);
        
        pair.mint();
        uint256 lpToken = pair.balanceOf(lp);
        assertEq(lpToken, 1e18-1000);
    }

    function testExistLiquidity() public {
        testInitialMint();
        vm.startPrank(lp);
        token0.transfer(address(pair),1 ether);
        token1.transfer(address(pair),1 ether);
        
        pair.mint();
        uint256 lpToken = pair.balanceOf(lp);
        assertEq(lpToken, 2e18-1000);
    }

    function testUnbalancedLiquidity() public {
        testInitialMint();
        vm.startPrank(lp);
        token0.transfer(address(pair),2 ether);
        token1.transfer(address(pair),1 ether);
        
        pair.mint();
        uint256 lpToken = pair.balanceOf(lp);
        assertEq(lpToken, 2e18-1000);
    }

    function testBurn() public{
        testInitialMint();
        vm.startPrank(lp);
        pair.burn();
        assertEq(pair.balanceOf(lp), 0);
        assertEq(token0.balanceOf(lp), 10 ether-1000);
        assertEq(token1.balanceOf(lp), 10 ether-1000);
    }

    function testUnbalancedBurn() public {
        testInitialMint();
        vm.startPrank(lp);
        token0.transfer(address(pair),2 ether);
        token1.transfer(address(pair),1 ether);
        
        pair.mint();
        uint256 lpToken = pair.balanceOf(lp);
        assertEq(lpToken, 2e18-1000);

        pair.burn();
        assertEq(pair.balanceOf(lp), 0);
        assertEq(token0.balanceOf(lp), 10 ether-1500);
        assertEq(token1.balanceOf(lp), 10 ether-1000);
    }
}