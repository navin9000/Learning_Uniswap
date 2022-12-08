//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

import "./interfaces/IuniswapV2Pair.sol";
import "./interfaces/IERC20.sol";


///@title Router contract
///@author Naveen Pulamarasetti
///@notice which is router contract between endUser and core Contract and only for experimental purpose
///@dev not testing completly, under developing stage
///@custom:experimental this is experimental contract of uniswapV2


contract UniswapV2Router{
    address public factory;

    
    mapping(address => mapping(address => address)) allTokenAddr;  //mapping(tokenA => mapping(tokenB => contractAddr))

    constructor(address _factory){
        factory = _factory;
    }

    ///@notice connecting router with uniswapV2pair contract
    ///@dev adding the new contract pair to the router 
    ///@param contr_addr is address of contract Pair
    ///@param tokenA is contract address of ERC20 tokenA
    ///@param tokenB is contract address of ERC20 tokenB
    function addNewPairAddress(
        address contr_addr,
        address tokenA,
        address tokenB
        )
        public 
    {
        require(contr_addr != address(0) && (tokenA != address(0) && tokenB != address(0)),"found zero address");
        allTokenAddr[tokenA][tokenB] = contr_addr;
        allTokenAddr[tokenB][tokenA] = contr_addr;
    }

  
    ///@notice transfer function
    ///@dev safety check for ERC20 tokens tranfer/tranferFrom returns bool value , bascically transaction executes either true or false
    function _safeTransfer(
        address _token,
        address _to,
        uint256 _amt
        )
        internal
    {
        require(_amt > 0,"insuffiencent transfer");
        bool check = IERC20(_token).transferFrom(address(this),_to,_amt);
        require(check,"transfer failed");
    }


    
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 desiredAmtTokenA,
        uint256 desiredAmtTokenB,
        uint256 amtAMin,
        uint256 amtBMin
    )
    internal
     virtual
      returns(
        uint256 amtA,
        uint256 amtB
        )
    {
        address contr_addr = allTokenAddr[tokenA][tokenB];
        (uint256 reservesA,uint256 reservesB) = IuniswapV2Pair(contr_addr).getReserves();

        if(reservesA == 0 && reservesB == 0){
            return(desiredAmtTokenA,desiredAmtTokenB);
        }
        else{
            //If all A tokens are considered , calculating the optimal tokens of B 
            uint256 optTokenB = (reservesB*desiredAmtTokenA)/reservesA;
            if(reservesB >= optTokenB){
                require(optTokenB >= amtBMin,"insufficent tokens of B");
                return (desiredAmtTokenA,optTokenB);
            }
            else{
                //If all B tokens are considered , calculating the optimal tokens of A 
                uint256 optTokenA = (reservesA*desiredAmtTokenB)/reservesB;
                require(optTokenA >= amtAMin,"insufficent tokens of A");
                return (optTokenA,desiredAmtTokenB);
            }
        }
    }

     //

     ///@notice adding liquidity to the pool
     ///@notice 1.getting amount to add by calling _addLiquidity() function
     ///@notice 2.getting the token pair contract address and transfering the tokens to the contract pair
     ///@notice 3.calling the pair contract function mint(to), return LP tokens for providing liquidity to the caller 
     ///@param tokenA is ERC20 token contract address
     ///@param tokenB is ERC20 token contract address
     ///@param desiredAmtTokenA is the liquidity provider desired token amount of A
     ///@param desiredAmtTokenB is the liquidity provider desired token amount of B
     ///@param amtAMin is minimum amount of A want to add Liquidity pool
     ///@param amtBMin is minimum amount of B want to add to liquidity pool
     ///@param to the address of the caller
     ///@return amtA the amount of tokensA added to liquidity
     ///@return amtB the amount of tokensB added to liquidity
     ///@return liquidity the amount of LP tokens returned to the user
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 desiredAmtTokenA,
        uint256 desiredAmtTokenB,
        uint256 amtAMin,
        uint256 amtBMin,
        address to
    )
    external
     virtual 
     returns(
        uint256 amtA,
        uint256 amtB,
        uint256 liquidity
        )
    {
        (amtA,amtB) = _addLiquidity(tokenA,tokenB,desiredAmtTokenA,desiredAmtTokenB,amtAMin,amtBMin);
        address contr_addr = allTokenAddr[tokenA][tokenB];

        _safeTransfer(tokenA,contr_addr,amtA);
        _safeTransfer(tokenB,contr_addr,amtB);

        liquidity = IuniswapV2Pair(contr_addr).mint(to);
    }

}
