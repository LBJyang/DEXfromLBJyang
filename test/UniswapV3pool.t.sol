// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//import "forge-std/Test.sol";
import "../lib/forge-std/src/Test.sol";
import "./ERC20Mintable.sol";
import "../src/Uniswapv3pool.sol";
import "./TestUtils.sol";

contract UniswapV3PoolTest is Test, TestUtils {
    ERC20Mintable token0;
    ERC20Mintable token1;
    Uniswapv3pool pool;
    bool transferInMintCallback = true;
    bool transferInSwapCallback = true;

    struct TestCaseParams {
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
        token0 = new ERC20Mintable("Ether", "ETH", 18);
        token1 = new ERC20Mintable("USDC", "USDC", 18);
    }

    function testMintSuccess() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: 85176,
            lowTick: 84222,
            upperTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiquidity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setUpTestCases(params);
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
        bytes32 positionKey = keccak256(
            abi.encodePacked(address(this), params.lowTick, params.upperTick)
        );
        uint128 posLiquidity = pool.positions(positionKey);
        assertEq(posLiquidity, params.liquidity, "Error Liquidity!");
        (uint160 sqrtPriceX96, int24 tick) = pool.slot0();
        assertEq(sqrtPriceX96, params.currentSqrtP, "Error price!");
        assertEq(tick, params.currentTick, "Error tick!");
        assertEq(pool.liquidity(), params.liquidity, "Error liquidity!");
    }

    function testMintInvalidTickRangeLower() public {
        pool = new Uniswapv3pool(
            address(token0),
            address(token1),
            uint160(1),
            0
        );
        vm.expectRevert(encodeError("InvalidTickRange()"));
        pool.mint(address(this), -887273, 0, 0, "");
    }

    function testMintInvalidTickRangeupper() public {
        pool = new Uniswapv3pool(
            address(token0),
            address(token1),
            uint160(1),
            0
        );
        vm.expectRevert(encodeError("InvalidTickRange()"));
        pool.mint(address(this), 0, 0, 887273, "");
    }

    function testMintZeroLiquidity() public {
        pool = new Uniswapv3pool(
            address(token0),
            address(token1),
            uint160(1),
            0
        );
        vm.expectRevert(encodeError("ZeroLiquidity()"));
        pool.mint(address(this), 0, 1, 0, "");
    }

    /*
     * @notice Describe the main purpose of the function
     * @dev Include additional implementation details here
     * @param  Description of the purpose of parameter 1
     * @param  Description of the purpose of parameter 2
     * @return Description of the return value
     */
    function testSwapSuccess() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: 85176,
            lowTick: 84222,
            upperTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiquidity: true
        });
        setUpTestCases(params);
        token1.mint(address(this), 42 ether);
        token1.approve(address(this), 42 ether);

        uint256 token0BalanceBefore = token0.balanceOf(address(this));

        Uniswapv3pool.CallBackData memory extra = Uniswapv3pool.CallBackData({
            token0: address(token0),
            token1: address(token1),
            payer: address(this)
        });

        (int256 amount0Delta, int256 amount1Delta) = pool.swap(
            address(this),
            abi.encode(extra)
        );

        assertEq(amount0Delta, -0.008396714242162444 ether, "invalid ETH out!");
        assertEq(amount1Delta, 42 ether, "invalid usdc out!");
        //assertTrue(true);
        assertEq(
            token0.balanceOf(address(this)),
            uint256(int256(token0BalanceBefore) - amount0Delta),
            "invalid user ETH!"
        );
        assertEq(
            token1.balanceOf(address(this)),
            0,
            "invalide user USDC balance!"
        );
    }

    function testSwapInsufficientSupply() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: 85176,
            lowTick: 84222,
            upperTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiquidity: true
        });
        setUpTestCases(params);
        vm.expectRevert(encodeError("InsufficentInputAmount()"));
        token1.approve(address(this), 32 ether);
        Uniswapv3pool.CallBackData memory extra = Uniswapv3pool.CallBackData({
            token0: address(token0),
            token1: address(token1),
            payer: address(this)
        });

        pool.swap(address(this), abi.encode(extra));
    }

    /*
     * @notice 按照设定参数运行mint函数。
     * @dev Include additional implementation details here
     * @param  Description of the purpose of parameter 1
     * @param  Description of the purpose of parameter 2
     * @return 返回mint函数的返回值。
     */
    function setUpTestCases(
        TestCaseParams memory params
    ) internal returns (uint256 poolBalance0, uint256 poolBalance1) {
        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.usdcBalance);
        //生成pool合约
        pool = new Uniswapv3pool(
            address(token0),
            address(token1),
            params.currentSqrtP,
            params.currentTick
        );
        //通过flag确定hi否运行mint函数。
        if (params.mintLiquidity) {
            token0.approve(address(this), params.wethBalance);
            token1.approve(address(this), params.usdcBalance);
            Uniswapv3pool.CallBackData memory extra = Uniswapv3pool
                .CallBackData({
                    token0: address(token0),
                    token1: address(token1),
                    payer: address(this)
                });
            //运行mint函数
            (poolBalance0, poolBalance1) = pool.mint(
                address(this),
                params.lowTick,
                params.upperTick,
                params.liquidity,
                abi.encode(extra)
            );
        }
        transferInMintCallback = params.transferInMintCallback;
        transferInSwapCallback = params.transferInSwapCallback;
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

    function uniswapV3SwapCallback(
        int256 amount0,
        int256 amount1,
        bytes calldata data
    ) public {
        Uniswapv3pool.CallBackData memory extra;
        if (transferInSwapCallback) {
            extra = abi.decode(data, (Uniswapv3pool.CallBackData));
        }
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
