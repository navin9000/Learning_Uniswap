//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

// import "ds-test/test.sol";
import "../periphery/token0.sol";
import "../periphery/token1.sol";
import "../core/uniswapV2Pair.sol";
import "../core/uniswapV2ERC20.sol";

// import "ds-test/test.sol";




contract UniswapV2PairTest{
    //deploying two contract token objects
    Token0 _token0 = new Token0();
    Token1 _token1 = new Token1();
 

    //UniswapV2Pair contract object
    UniswapV1Pair vp = new UniswapV1Pair();
    
    //uniswapV2ERC20 token
    UniswapV2ERC20 vpERC = new UniswapV2ERC20();








     





}