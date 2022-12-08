//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

interface IuniswapV2Pair{

    function getReserves() external returns(uint112 _resvs0,uint112 _resvs1);

    function mint(address to)external returns(uint256 liquidity);

}