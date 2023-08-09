// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Exchange.sol";

contract Factory {
    address public exchangeTemplate;
    uint256 public tokenCount;
    mapping (address => address) tokenToExchange;
    mapping (address => address) exchangeToToken;
    mapping (uint256 => address) idToToken;

    event NewExchange(address token, address exchange);

    constructor() {
        
    }

    function initialFactory(address template) public {
        require(exchangeTemplate == address(0), "template address not zero");
        require(template != address(0), "empty template address");
        exchangeTemplate = template;
    }

    function createExchange(address token) public returns(address){
        require(token != address(0), "token zero address");
        require(exchangeTemplate != address(0), "exchange template zero address");
        require(tokenToExchange[token] == address(0), "exchange address not zero");
        address exchangeAddr = create_with_code_of(exchangeTemplate);
        Exchange exchange = Exchange(exchangeAddr);
        exchange.setup(token);
        tokenToExchange[token] = exchangeAddr;
        exchangeToToken[exchangeAddr] = token;
        uint256 tokenId = tokenCount + 1;
        tokenCount = tokenId;
        idToToken[tokenId] = token;
        emit NewExchange(exchangeAddr, token);
        return exchangeAddr;
    }

    function getExchange(address token) public view returns (address) {
        return tokenToExchange[token];
    }

    function getToken(address exchange) public view returns (address) {
        return exchangeToToken[exchange];
    }

    function getTokenWithId(uint256 tokenId) public view returns (address) {
        return idToToken[tokenId];
    }

    function create_with_code_of(address contractTemplate) internal returns (address newContract) {
        bytes memory code = type(Exchange).creationCode;
        assembly {
            newContract := create(0, add(code, 0x20), mload(code))
        }
    }
}