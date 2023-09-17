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
    bool transferInMintCallback;

    struct TestCaseParams{
        uint256 wethBalance;
        uint256 usdcBalance;
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

    function testMintSuccess() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance:1 ether,
            usdcBalance:5000 ether,
            currentTick:85176,
            lowTick:84222,
            upperTick:86129,
            liquidity:1517882343751509868544,
            currentSqrtP:5602277097478614198912276234240,
            transferInMintCallback:true,
            transferInSwapCallback:true,
            mintLiquidity:true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setUpTestCases(params);(params);
        uint256 expectedAmount0 = 0.998976618347425280 ether;
        uint256 expectedAmount1 = 5000 ether;
        assertEq(
            poolBalance0,
            expectedAmount0,
            "incorrect token0 deposited amount"
            );
        assertEq(
            poolBalance1,
            expectedAmount1,
            "incorrect token1 deposited amount"
            );
        assertEq(token0.balanceOf(address(pool)), expectedAmount0);
        assertEq(token1.balanceOf(address(pool)), expectedAmount1);
        bytes32 positionKey = keccak256(abi.encodePacked(address(this),params.lowTick,params.upperTick));
        uint128 posLiquidity = pool.positions(positionKey);
        assertEq(posLiquidity, params.liquidity, "Error Liquidity!");
    }

    function setUpTestCases(TestCaseParams memory params) internal returns(uint256 poolBalance0,uint256 poolBalance1){
        token0.mint(address(this),params.wethBalance);
        token1.mint(address(this),params.usdcBalance);
        transferInMintCallback = params.transferInMintCallback;

        pool = new Uniswapv3pool(
            address(token0),
            address(token1),
            params.currentSqrtP,
            params.currentTick
        );

        if(params.mintLiquidity){
            token0.approve(address(this), params.wethBalance);
            token1.approve(address(this), params.usdcBalance);
            Uniswapv3pool.CallBackData memory extra = Uniswapv3pool.CallBackData({
            token0:address(token0),
            token1:address(token1),
            payer:address(this)
        });
        (poolBalance0,poolBalance1) = pool.mint(address(this), params.lowTick, params.upperTick, params.liquidity, abi.encode(extra));
        }
        
        
    }

    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) public {
        if (transferInMintCallback) {
            Uniswapv3pool.CallBackData memory extra = abi.decode(
                data,
                (Uniswapv3pool.CallBackData)
            );

            IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
            IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1);
        }
    }
}