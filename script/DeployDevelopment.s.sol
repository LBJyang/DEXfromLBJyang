//SPDX-License-Identifier:BUSL-1.1
pragma solidity ^0.8.14;

import "../lib/forge-std/src/console.sol";
import "../lib/forge-std/src/Script.sol";
import "../test/ERC20Mintable.sol";
import "../src/Uniswapv3pool.sol";
import "../src/Uniswapv3Manager.sol";

contract DeployDevelopment is Script {
    function run() public {
        uint256 wethBalance = 1 ether;
        uint256 usdcBalance = 5042 ether;
        int24 currentTick = 85176;
        uint160 currentSqrtP = 5602277097478614198912276234240;
        vm.startBroadcast();
        ERC20Mintable token0 = new ERC20Mintable("Wrapped ETH", "WETH", 18);
        ERC20Mintable token1 = new ERC20Mintable("usdc", "udsc", 18);
        Uniswapv3pool pool = new Uniswapv3pool(
            address(token0),
            address(token1),
            currentSqrtP,
            currentTick
        );
        Uniswapv3Manager manager = new Uniswapv3Manager();
        token0.mint(msg.sender, wethBalance);
        token1.mint(msg.sender, usdcBalance);
        vm.stopBroadcast();

        console.log("WETH address:", address(token0));
        console.log("USDC address:", address(token1));
        console.log("pool address:", address(pool));
        console.log("Manager address:", address(manager));
    }
}
