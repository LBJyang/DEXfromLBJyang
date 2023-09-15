// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//import "forge-std/Test.sol";
import "../lib/forge-std/src/Test.sol";
import "./ERC20Mintable.sol";
import "../src/Uniswapv3pool.sol";

contract UniswapV3PoolTest is Test {
    ERC20Mintable token0;
    ERC20Mintable token1;
    Uniswapv3pool pool;

    struct TestCaseParams{
        uint256 wethBalance;
        uint256 udscBalance;
        int24 currentTick;
        int24 lowTick;
        int24 upperTick;
        uint128 liquidity;
        uint160 currentSqrtP;
        bool transferInMintCallback;
        bool transferInSwapCallback;
        bool mintLiquidity;
    }

    function setUp() public {
        token0 = new ERC20Mintable("Ether","ETH",18);
        token1 = new ERC20Mintable("USDC","USDC",18);

    }

    function testExample() public {
        assertTrue(true);
    }
}