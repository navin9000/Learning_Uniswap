//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

interface IERC20{

    function transferFrom(address from,address to,uint256 amt)external returns(bool);
}