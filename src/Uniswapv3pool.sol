//SPDX-License-Identifier:BUSL-1.1
pragma solidity ^0.8.14;

import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV3MintCallback.sol";

import "../lib/Tick.sol";
import "../lib/Position.sol";

contract Uniswapv3pool {
    address public immutable token0;
    address public immutable token1;
    uint128 public liquidity;
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;
    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
    }
    struct CallBackData{
        address token0;
        address token1;
        address payer;
    }

    Slot0 public slot0;

    mapping(int24 => Tick.Info) public ticks;
    mapping(bytes32 => Position.Info) public positions;

    using Tick for mapping(int24 => Tick.Info);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;

    error InvalidTickRange();
    error ZeroLiquidity();
    error InsufficentInputAmount();

    event Mint(
        address sender,
        address indexed owner,
        int24 indexed lowTick,
        int24 indexed upperTick,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    constructor(
        address token0_,
        address token1_,
        uint160 sqrtPriceX96_,
        int24 tick_
    ) {
        token0 = token0_;
        token1 = token1_;
        slot0 = Slot0({sqrtPriceX96: sqrtPriceX96_, tick: tick_});
    }

    function mint(
        address owner,
        int24 lowTick,
        int24 upperTick,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1) {
        if (upperTick <= lowTick || lowTick < MIN_TICK || upperTick > MAX_TICK)
            revert InvalidTickRange();
        if (amount == 0) revert ZeroLiquidity();
        ticks.update(upperTick, amount);
        ticks.update(lowTick, amount);
        Position.Info storage position = positions.get(
            owner,
            lowTick,
            upperTick
        );
        position.update(amount);

        liquidity += uint128(amount);

        amount0 = 0.998976618347425280 ether;
        amount1 = 5000 ether;

        uint256 balanceBefore0;
        uint256 balanceBefore1;

        if(amount0 > 0) balanceBefore0 = balance0();
        if(amount1 > 0) balanceBefore1 = balance1();

        IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(
            amount0,
            amount1,
            data
        );

        if (amount0 > 0 && balanceBefore0 + amount0 > balance0())
            revert InsufficentInputAmount();
        if (amount1 > 0 && balanceBefore1 + amount1 > balance1())
            revert InsufficentInputAmount();

        emit Mint(
            msg.sender,
            owner,
            lowTick,
            upperTick,
            amount,
            amount0,
            amount1
        );
    }

    /*
    Internal
    */
    function balance0() internal returns (uint256 balance) {
        balance = IERC20(token0).balanceOf(address(this));
    }

    function balance1() internal returns (uint256 balance) {
        balance = IERC20(token1).balanceOf(address(this));
    }
}
