//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";


contract Token1 is ERC20{

    constructor()ERC20("ZIA","Z"){
    }

    function _mintToken1(uint256 amt)public{
        _mint(msg.sender,amt);
    }
}