//SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.7;

//imports
import "./interfaces/IuniswapV2Factory.sol";
import "./uniswapV2Pair.sol";

/**
 * @title registry for UniswapV2Pair contracts
 */
contract UniswapV2Factory is IuniswapV2Factory {
    ///mapping(tokenA => mapping(tokenB => contract address));
    mapping(address => mapping(address => address)) public override getPair;
    ///all UniswapV2Pair contract addresses
    address[] public allPairs;

    //events
    event pairCreated(address, address, address);

    /**
     * @dev creating new tokenPair contract address
     * @param tokenA is token address
     * @param tokenB is token address
     * @return _contr_addr returning the newly created pair tokens contract address
     */
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address _contr_addr) {
        require(tokenA != tokenB, "identical tokens");
        require(
            tokenA != address(0) && tokenB != address(0),
            "found zero address"
        );
        (address token0, address token1) = tokenA > tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(getPair[token0][token1] == address(0), "pair aleardy existed");
        UniswapV2Pair contr_addr = new UniswapV2Pair(token0, token1);

        getPair[token0][token1] = address(contr_addr);
        getPair[token1][token0] = address(contr_addr);
        allPairs.push(address(contr_addr));

        emit pairCreated(token0, token1, address(contr_addr));

        return address(contr_addr);
    }
}
