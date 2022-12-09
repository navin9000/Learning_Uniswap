//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

interface IuniswapV2Pair{

    function getReserves() external returns(uint112 _resvs0,uint112 _resvs1);

    function mint(address to)external returns(uint256 liquidity);

    function transferFrom(address from,address to,uint256 amount)external returns(bool );

    function burn(address to)external returns(uint256 _amt0,uint256 _amt1);

}