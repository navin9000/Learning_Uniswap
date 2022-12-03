//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

//importing solmate ERC20 token contract
import "solmate/tokens/ERC20.sol";


contract UniswapV2ERC20 is ERC20{
    
    constructor()ERC20("UniswapV2","LP",18){
        
    }
}