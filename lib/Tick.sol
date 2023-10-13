//SPDX-License-Identifier:BUSL-1.1
pragma solidity ^0.8.14;

library Tick {
    //结构体用来保存tick信息，包括这个tick是否被提供过流动性，以及这个tick的总体流动性是多少。
    struct Info {
        bool initialized;
        uint128 liquidity;
    }

    /*
     * @notice 更新tick信息。具体说是更新tick=>tickInfo这个信息。
     * @dev
     * @param  tick是range端点，liquidityDelta是新提供的流动性。mapping是一个映射，对应主合约ticks。
     * @param  这里的参数是个疑问，函数的参数是三个，但是调用只需要两个就可以调用。这种情况没见过。
     * @param  我目前的理解：这个参数单纯是为了引入映射，而这个映射在主合约中有定义。实际上这个参数就是主
     合约中的ticks。映射的架构都是int24指向Tick.Info,但这样就可以算作是一个mapping吗？
     * @return 这个函数的结论就是更新了ticks这个映射，ticks[tick] = Tick.Info。更新initialized和liquidity。
     */
    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint128 liquidityDelta
    ) internal {
        Tick.Info storage tickInfo = self[tick];
        uint128 liquidityBefore = tickInfo.liquidity;
        uint128 liquidityAfter = liquidityBefore + liquidityDelta;
        tickInfo.liquidity = liquidityAfter;
        if (liquidityBefore == 0) {
            tickInfo.initialized = true;
        }
    }
}
