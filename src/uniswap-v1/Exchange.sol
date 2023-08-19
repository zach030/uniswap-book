// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IExchange {
    function ethToTokenSwap(uint256 _minTokens) external payable;

    function ethToTokenTransfer(uint256 _minTokens, address _recipient)
        external
        payable;
}

interface IFactory {
    function getExchange(address _tokenAddress) external returns (address);
}

contract Exchange is ERC20 {
    address public tokenAddress;
    address public factroryAddress;

    constructor(address _token) ERC20("Zuniswap-V1", "ZUNI-V1") {
        require(_token != address(0), "invalid token address");
        tokenAddress = _token;
        factroryAddress = msg.sender;
    }

    function addLiquidity(uint256 tokenAmount) public payable{
        uint256 tokenReserve = getReserve();
        IERC20 token = IERC20(tokenAddress);
        if (tokenReserve==0){
            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);
            token.transferFrom(msg.sender, address(this), tokenAmount);
        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 needTokenAmount = (tokenReserve * msg.value) / ethReserve;
            require(needTokenAmount <= tokenAmount, "insufficient token amount");
            token.transferFrom(msg.sender, address(this), needTokenAmount);
            uint256 liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);
        }
    }

    function removeLiquidity(uint256 _amount) public returns (uint256, uint256) {
        require(_amount > 0, "invalid amount");

        uint256 ethAmount = (address(this).balance * _amount) / totalSupply();
        uint256 tokenAmount = (getReserve() * _amount) / totalSupply();

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        return (ethAmount, tokenAmount);
    }

    function getReserve() public view returns(uint256){
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getAmount(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve)
        public
        pure
        returns (uint256){
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        uint256 numerator = (inputAmount*99) * outputReserve;
        uint256 denominator = (inputReserve * 100) + (inputAmount*99);
        return numerator / denominator;        
    }

    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        require(_ethSold > 0, "ethSold is too small");

        uint256 tokenReserve = getReserve();

        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
        require(_tokenSold > 0, "tokenSold is too small");

        uint256 tokenReserve = getReserve();

        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    function ethToToken(uint256 _minTokens, address recipent) private {
        uint256 tokenReserve = getReserve();
        uint256 inputAmount = msg.value;
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 outputTokenAmount = getAmount(
            inputAmount,
            ethReserve,
            tokenReserve
        );

        require(outputTokenAmount >= _minTokens, "insufficient output amount");

        IERC20(tokenAddress).transfer(recipent, outputTokenAmount);       
    }

    function ethToTokenSwap(uint256 _minTokens) public payable {
        ethToToken(_minTokens, msg.sender);
    }

    function ethToTokenTransfer(uint256 _minTokens, address _recipient) public payable {
        ethToToken(_minTokens, _recipient);
    }

    function tokenToETHSwap(uint256 _tokenSold, uint256 _minEth) public payable {
        uint256 tokenReserve = getReserve();
        uint256 ethReserve = address(this).balance;
        uint256 outputETHAmount = getAmount(
            _tokenSold,
            tokenReserve,
            ethReserve
        );

        require(outputETHAmount >= _minEth, "insufficient output amount");
        
        IERC20(tokenAddress).transferFrom(msg.sender,address(this), _tokenSold);
        payable(msg.sender).transfer(outputETHAmount);
    }

    function tokenToTokenSwap(uint256 _tokenSold, uint256 _minTokenBought, address _targetTokenAddress) public {
        // exchange if exist
        address exchange = IFactory(factroryAddress).getExchange(_targetTokenAddress);
        require(exchange!=address(0) && exchange!=address(this), "exchange not exist");
        // token to eth
        uint256 tokenReserve = getReserve();
        uint256 ethReserve = address(this).balance;
        uint256 outputETHAmount = getAmount(
            _tokenSold,
            tokenReserve,
            ethReserve
        );
        
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenSold);
        // another exchange eth to token
        IExchange(exchange).ethToTokenTransfer{value: outputETHAmount}(_minTokenBought, msg.sender);
    }
}