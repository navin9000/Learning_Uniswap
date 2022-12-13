//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

import "ds-test/test.sol";
import "forge-std/Test.sol";

import "../core/uniswapV2Pair.sol";
import "../core/uniswapV2Factory.sol";
import "../mock/token0.sol";
import "../mock/token1.sol";

contract UniswapV2pairTest is DSTest, Test {
    Token0 token0;
    Token1 token1;
    UniswapV2Pair pair;

    // TestUser testUser;

    ///setUp : an optional function invoked before each test case is run
    function setUp() public {
        token0 = new Token0();
        token1 = new Token1();

        UniswapV2Factory factory = new UniswapV2Factory();

        pair = UniswapV2Pair(
            factory.createPair(address(token0), address(token1))
        );

        ///minting tokens
        token0._mintToken0(address(this), 1000 ether);
        token1._mintToken1(address(this), 1000 ether);
    }

    ///test : functions prefixed with test are run as test cases
    function testMint() public {}
}
