//SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.7;

interface IuniswapV2Factory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}
