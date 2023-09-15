//SPDX-License-Identifier:MIT
pragma solidity ^0.8.14;

library Position {
    struct Info {
        uint128 liquidity;
    }

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

    function update(Info storage self, uint128 liquidityDelta) internal {
        uint128 liquidityBefore = self.liquidity;
        uint128 liquidityAfter = liquidityBefore + liquidityDelta;
        self.liquidity = liquidityAfter;
    }
}
