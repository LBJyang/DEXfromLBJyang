// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "../src/Uniswapv3pool.sol";

contract TestUtils {
    function encodeError(
        string memory error
    ) internal pure returns (bytes memory encoded) {
        encoded = abi.encodeWithSignature(error);
    }
}
