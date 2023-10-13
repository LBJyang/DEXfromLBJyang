//SPDX-License-Identifier:BUSL-1.1
pragma solidity ^0.8.14;

import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV3MintCallback.sol";
import "./interfaces/IUniswapV3SwapCallback.sol";
import "../lib/Tick.sol";
import "../lib/Position.sol";

/**
 * @title 项目的核心合约。实现了最基础的两个功能。提供流动性和代币swap。
 * @notice milestone1阶段，流动性区间确定，价格确定，tick确定。
 */
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
    struct CallBackData {
        address token0;
        address token1;
        address payer;
    }

    Slot0 public slot0;

    //tick到Tick.Info的映射。
    mapping(int24 => Tick.Info) public ticks;
    //bytes32到Position.Info的映射。
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
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /*
     * @notice 构造函数，
     * @dev Include additional implementation details here
     * @param  Description of the purpose of parameter 1
     * @param  Description of the purpose of parameter 2
     * @return Description of the return value
     */
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

    /*
     * @notice Describe the main purpose of the function
     * @dev Include additional implementation details here
     * @param  amount是要提供的流动性。为什么不直接以代币数量作为参数，而使用流动性？还需要通过代币数量、边界
     代币价格计算出来的流动性。意义何在？
     * @param  Description of the purpose of parameter 2
     * @return Description of the return value
     */
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

        if (amount0 > 0) balanceBefore0 = balance0();
        if (amount1 > 0) balanceBefore1 = balance1();
        //回调函数，来完成代币的支付。使用回调函数的理由：Using a callback here,
        //this is critical because we cannot trust users.
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
     * @notice Describe the main purpose of the function
     * @dev Include additional implementation details here
     * @param  Description of the purpose of parameter 1
     * @param  Description of the purpose of parameter 2
     * @return Description of the return value
     */
    function swap(
        //普通意义理解，swap不是应该输入卖出的token数量，返回买入的token数量么？参数是接收地址是什么意思？
        //难道还允许非owner进行swap吗？A卖出token0,swap回来的token1给B？
        //这里data没有校验，可能会出现data.payer的token1余额不足的情况。
        address recipient,
        bytes calldata data
    ) public returns (int256 amount0, int256 amount1) {
        //计算出nettick和price
        int24 nextTick = 85184;
        uint160 nextPrice = 5604469350942327889444743441197;

        amount0 = -0.008396714242162444 ether;
        amount1 = 42 ether;
        //更新slot0
        (slot0.sqrtPriceX96, slot0.tick) = (nextPrice, nextTick);
        //这个函数的从msg.sender进行转出，也就是从本合约转出。这里是不是有reentry风险？
        IERC20(token0).transfer(recipient, uint256(-amount0));
        uint256 balance1Before = balance1();
        //回调函数。从data.payer向本合约支付应转入的代币。如果data.payer的被授权的余额不足，这里会返回
        //错误。执行结束。那么之前的转出就可能被黑掉？
        IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(
            amount0,
            amount1,
            data
        );
        //这里如果payer的余额不足，上一个语句就不会执行成功。下面的语句就是没有意义的了。
        if (balance1Before + uint256(amount1) > balance1())
            revert InsufficentInputAmount();
        emit Swap(
            msg.sender,
            recipient,
            amount0,
            amount1,
            slot0.sqrtPriceX96,
            liquidity,
            slot0.tick
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
/**
 * @title ContractTitle - Description of the contract's purpose
 * @notice Describe the primary function and usage of the contract
 */

/*
 * @notice Describe the main purpose of the function
 * @dev Include additional implementation details here
 * @param  Description of the purpose of parameter 1
 * @param  Description of the purpose of parameter 2
 * @return Description of the return value
 */
