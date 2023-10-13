//SPDX-License-Identifier:MIT
pragma solidity ^0.8.14;

library Position {
    struct Info {
        uint128 liquidity;
    }

    /*
     * @notice 通过流动性提供者owner，上tick，下tick来获取positions.Info。目前Info里只有liquidity，
     也就是说通过三个参数获取对应的流动性：这个人在这个区间上的流动性。这个函数其实是替代了uniswapv2中
     的mint流动性代币的部分，用position.info标记一个owner持有的流动性数量。
     * @dev Include additional implementation details here
     * @param  owner是流动性提供者。
     * @param  Description of the purpose of parameter 2
     * @return 返回的是Info，Info里只有liquidity。这个流动性是总流动性，不是新增流动性。
     */
    function get(
        mapping(bytes32 => Info) storage self,
        address owner,
        int24 lowTick,
        int24 upperTick
    ) external view returns (Position.Info storage position) {
        return
            position = self[
                keccak256(abi.encodePacked(owner, lowTick, upperTick))
            ];
    }

    /*
     * @notice 更新position.info。这个info是对应了某个用户及上下tick的info。
     * @param  Description of the purpose of parameter 2
     * @return 更新liquidity。
     */
    function update(Info storage self, uint128 liquidityDelta) internal {
        uint128 liquidityBefore = self.liquidity;
        uint128 liquidityAfter = liquidityBefore + liquidityDelta;
        self.liquidity = liquidityAfter;
    }
}
