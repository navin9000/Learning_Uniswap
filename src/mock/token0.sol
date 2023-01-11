//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

// import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "lib/solmate/src/tokens";

contract Token0 is ERC20 {
    constructor() ERC20("ZIA", "Z", 18) {}

    function _mintToken0(address to, uint256 amt) public {
        _mint(to, amt);
    }
}
