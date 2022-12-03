//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

//importing interfaces
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";



import "./uniswapV2ERC20.sol";

//importing the libraries Math.sol and UQ112x112.sol
import "./libraries/Math.sol";
import "./libraries/UQ112x112.sol";

/* What is libraries/UQ112x112 ? 
 * Solidity doesn't support floating point numbers so uniswap uses binary point format to encode and manipulate data
 * And if you're wondering why solidity doesn't support floating point numbers then open your browser console and calculate `0.1 + 0.2`.
   This will eventually cause rounding errors
 * UQ112x112 means 112 bits uses for left of the decimal and 112 uses for right of the decimal, which is total 224 bits.
   224 leaves 32 bits from 256 bits(which is max capacity of a storage slot)
 * Price could fit in 224 bits but accumulation not. The extra 32 bits is for price accumulation.
 * Reserves are also using this format, so both reserves can fit in 224 bits and 32 bits is lefts for timestamp.
 * Timestamp could be bigger than 32 bits that's why they mod it by 2**32, so it can fit in 32 bits even after 100 years. (check `_update` function)
 * They are saving 3 variables (reserve0 + reserve1 + blockTimestampLast) in a single storage slot for saving gas as we know storage is so expensive
 
 * Ethereum storage: https://programtheblockchain.com/posts/2018/03/09/understanding-ethereum-smart-contract-storage/
 * Uniswap v2 whitepaper: https://uniswap.org/whitepaper.pdf (2.2.1 Precision)
 */




//creating the UniswapV1Pair contract which is low-level contract

contract UniswapV1Pair is UniswapV2ERC20{

    using Math for uint256;
    using UQ112x112 for uint112;
    uint256 public MINIMUM_LIQUIDITY=1000;

    //token0 and token1 contract addresses
    address public token0;
    address public token1;


    uint112 private reserves0;
    uint112 private reserves1;


    //constructor
    constructor(address _token0,address _token1){
        token0=_token0;
        token1=_token1;
    }



    //events
    event Mint(address to,uint256 amt0,uint256 amt1);

    //STEPS :
    //1. getting the reserves of the token0 and token1 of the pool
    //2. getting the amount of tokens token0 and token1 hold by the contract (i.e reserves tokens + approved() tokens)
    //3. local variable liquidity is to hold the number of minted LP tokens and return it
    //4. Adding Liquidity divided into two branches :
        //1.If there is no liquidity in the pool
        //LP tokens are calculated by the formula :
        //UniswapV2 people used geometric mean formula = sqrt(amt0 * amt1) - MINIMUM_LIQUIDITY (i.e 1000)
        //
        
        //2.If aleardy having liquidity in the pool
        //NOTE: Liquidity provider can only put 1 desired amount of tokens another token amount is calculated relative to the ratios in the pool


    
    function getReserves()internal view returns(uint112 _resvs0,uint112 _resvs1){
        _resvs0=reserves0;
        _resvs1=reserves1;
    }

    function mint(address to)external returns(uint256 _liquidity){
        (uint112 _reserves0,uint112 _reserves1) = getReserves();

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amt0 = balance0 - _reserves0;
        uint256 amt1 = balance1 - _reserves1;

        uint256 liquidity;

        uint256 _totalSupply = totalSupply;

        if(_totalSupply==0){
            liquidity=Math.sqrt(amt0 * amt1) - MINIMUM_LIQUIDITY;
        }
        else{
            liquidity = Math.min((_totalSupply*amt0/_reserves0),(_totalSupply*amt1/_reserves1));
        }

        require(liquidity<0,"Insuffiecient LP tokens are minted ");

        _mint(to,liquidity);

        emit Mint(to,amt0,amt1);

        return liquidity;

    }


}