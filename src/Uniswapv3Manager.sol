//SPDX-License-Identifier:BUSL-1.1
pragma solidity ^0.8.14;

import "./Uniswapv3pool.sol";
import "./interfaces/IERC20.sol";

contract Uniswapv3Manager {
    function mint(
        address poolAddress_,
        int24 lowTick,
        int24 upperTick,
        uint128 liquidity,
        bytes calldata data
    ) public {
        Uniswapv3pool(poolAddress_).mint(
            msg.sender,
            lowTick,
            upperTick,
            liquidity,
            data
        );
    }

    function swap(address poolAddress_, bytes calldata data) public {
        Uniswapv3pool(poolAddress_).swap(msg.sender, data);
    }

    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) public {
        Uniswapv3pool.CallBackData memory extra = abi.decode(
            data,
            (Uniswapv3pool.CallBackData)
        );
        IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
        IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1);
    }

    function uniswapV3SwapCallback(
        int256 amount0,
        int256 amount1,
        bytes calldata data
    ) public {
        Uniswapv3pool.CallBackData memory extra;
        extra = abi.decode(data, (Uniswapv3pool.CallBackData));
        if (amount0 > 0) {
            IERC20(extra.token0).transferFrom(
                extra.payer,
                msg.sender,
                uint256(amount0)
            );
        }
        if (amount1 > 0) {
            IERC20(extra.token1).transferFrom(
                extra.payer,
                msg.sender,
                uint256(amount1)
            );
        }
    }
}
