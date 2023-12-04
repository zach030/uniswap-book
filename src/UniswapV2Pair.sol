// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";
import "./libraries/Math.sol";

interface IERC20 {
    function balanceOf(address) external returns (uint256);

    function transfer(address to, uint256 amount) external;
}

error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();
error TransferFailed();

contract UniswapV2Pair is ERC20, Math{
    uint256 constant MINIMUM_LIQUIDITY = 1000;
    address public token0;
    address public token1;

    uint256 private reserve0;
    uint256 private reserve1;

    event Burn(address indexed sender, uint256 amount0, uint256 amount1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Sync(uint256 reserve0, uint256 reserve1);

    constructor(address token0_, address token1_) 
        ERC20("","",18)
    {
        token0 = token0_;
        token1 = token1_;
    }

    function mint() public {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        // 计算新的存款金额
        uint256 amount0 = balance0-reserve0;
        uint256 amount1 = balance1-reserve1;

        uint256 liquidity;
        // 计算要发行的流动性代币数量
        if (totalSupply ==0 ){
            // 与存入的金额成正比，首次需要减去MINIMUM_LIQUIDITY，避免流动性池成本过高
            liquidity = sqrt(amount0*amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        }else {
            // 选择较小的作为流动性代币，避免用户不按比例投入流动性且获得更多的流动性代币
            liquidity = min(
                amount0 * totalSupply/reserve0,
                amount1 * totalSupply/reserve1
            );
        }
        if (liquidity <= 0){
            revert InsufficientLiquidityMinted();
        }
        // mint流动性代币
        _mint(msg.sender, liquidity);
        // 更新当前储备金
        _update(balance0, balance1);
        emit Mint(msg.sender, amount0, amount1);
    }

    function burn() external{
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[msg.sender];
        // 计算用户的流动性占比的token数量
        uint256 amount0 = liquidity * balance0 / totalSupply;
        uint256 amount1 = liquidity * balance1 / totalSupply;
        if (amount0 <=0 || amount1 <=0) revert InsufficientLiquidityBurned();
        // 流动性代币burn
        _burn(msg.sender, liquidity);
        // 转移token回给用户
        _safeTransfer(token0, msg.sender, amount0);
        _safeTransfer(token1, msg.sender, amount1);
        // 更新当前储备金
        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this)); 
        _update(balance0, balance1);
        emit Burn(msg.sender, amount0, amount1);
    }

    function sync() public {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this))
        );
    }

    function _update(uint256 balance0, uint256 balance1) private {
        // update reserve
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);

        emit Sync(reserve0, reserve1);
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, value)
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert TransferFailed();
    }
}
