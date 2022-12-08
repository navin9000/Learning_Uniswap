//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";


contract Token0 is ERC20{

    constructor()ERC20("GIRI","G"){
    }

    function _mintToken0(uint256 amt)public{
        _mint(msg.sender,amt);
    }
}