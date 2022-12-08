//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

import "./interfaces/IuniswapV2Pair.sol";
import "./interfaces/IERC20.sol";

//1.adding liquidity(empty is considered by reserves in the uniswapV2Pair contract)

contract UniswapV2Router{
    address public factory;

    //mapping(tokenA => mapping(tokenB => contractAddr))
    mapping(address => mapping(address => address)) allTokenAddr;

    constructor(address _factory){
        factory = _factory;
    }

    //Adding all new Contract addresses with token pairs is here

    function addNewPairAddress(address contr_addr,address tokenA,address tokenB)public {
        require(contr_addr != address(0) && (tokenA != address(0) && tokenB != address(0)),"found zero address");
        allTokenAddr[tokenA][tokenB] = contr_addr;
        allTokenAddr[tokenB][tokenA] = contr_addr;
    }

  
    //safety check for ERC20 tokens tranfer/tranferFrom returns bool value , irrespective of it
    //trasaction executes
    function _safeTransfer(address _token,address _to,uint256 _amt)internal{
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

     //1.getting amount to add by calling _addLiquidity() function
     //2.getting the token pair contract address and transfering the tokens to the contract pair
     //3.calling the pair contract function mint(to), return LP tokens for providing liquidity to the caller 
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
        uint256 amtB
        )
    {
        (amtA,amtB) = _addLiquidity(tokenA,tokenB,desiredAmtTokenA,desiredAmtTokenB,amtAMin,amtBMin);
        address contr_addr = allTokenAddr[tokenA][tokenB];

        _safeTransfer(tokenA,contr_addr,amtA);
        _safeTransfer(tokenB,contr_addr,amtB);

        IuniswapV2Pair(contr_addr).mint(to);
    }

}
