// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";
import "./libraries/Math.sol";

interface IERC20 {
    function balanceOf(address) external returns (uint256);

    function transfer(address to, uint256 amount) external;
}

contract UniswapV2Pair is ERC20, Math{
    uint256 constant MINIMUM_LIQUIDITY = 1000;
    address public token0;
    address public token1;

    uint256 private reserve0;
    uint256 private reserve1;

    constructor(address token0_, address token1_) 
        ERC20("","",18)
    {
        token0 = token0_;
        token1 = token1_;
    }

    function mint() public {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0-reserve0;
        uint256 amount1 = balance1-reserve1;

        uint256 liquidity;
        if (totalSupply ==0 ){
            liquidity = sqrt(amount0*amount1) - MINIMUM_LIQUIDITY;
            _mint(msg.sender, MINIMUM_LIQUIDITY);
        }else {
            liquidity = min(
                amount0 * totalSupply/reserve0,
                amount1 * totalSupply/reserve1
            );
        }
        if (liquidity <= 0){
            revert("");
        }
        _mint(msg.sender, liquidity);
    }
}
