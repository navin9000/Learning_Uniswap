//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

// import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "solmate/tokens/ERC20.sol";

contract Token1 is ERC20 {
    constructor() ERC20("GIRI", "G", 18) {}

    function _mintToken1(address to, uint256 amt) public {
        _mint(to, amt);
    }
}
