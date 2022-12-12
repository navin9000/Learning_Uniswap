//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

//importing interfaces
import "openzeppelin-contracts/token/ERC20/IERC20.sol";




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
    uint32 private blockTimestampLast;


    uint256 private unlocked=1;

    //modifier
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }


    //constructor
    constructor(address _token0,address _token1){
        token0=_token0;
        token1=_token1;
    }



    //events
    event Mint(address to,uint256 amt0,uint256 amt1);
    event Burn(address to,uint256 LpTokens);
    event Update(uint256 reserves0,uint256 reserves1);


    function update(uint256 _balance0,uint256 _balance1)internal{
        require(_balance0 < type(uint112).max || _balance1 < type(uint112).max,"balance overflow");
        
        //calculating the cumlative prices of token0 and token1
        //unchecked is to disable the overflow and underflow conditions of these varialbles
        // unchecked {
        //     uint32 timeElapsed = uint32(block.timestamp) - blockTimestampLast;

        //     if (timeElapsed > 0 && reserves0 > 0 && reserves1 > 0) {
        //         price0CumulativeLast +=
        //             uint256(UQ112x112.encode(reserves0).uqdiv(reserves1)) *
        //             timeElapsed;
        //         price1CumulativeLast +=
        //             uint256(UQ112x112.encode(reserves0).uqdiv(reserves1)) *
        //             timeElapsed;
        //     }
        // }

        reserves0 = uint112(_balance0);
        reserves1 = uint112(_balance1);
        blockTimestampLast = uint32(block.timestamp);

        emit Update(reserves0,reserves1);
    }

    //STEPS :
    //1. getting the reserves of the token0 and token1 of the pool
    //2. getting the amount of tokens token0 and token1 hold by the contract (i.e reserves tokens + approved() tokens)
    //3. local variable liquidity is to hold the number of minted LP tokens and return it
    //4. Adding Liquidity divided into two branches :
        //1.If there is no liquidity in the pool
        //LP tokens are calculated by the formula :
        //UniswapV2 people used geometric mean formula = sqrt(amt0 * amt1) - MINIMUM_LIQUIDITY (i.e 1000)
        //geometric mean ensures that intial liquidity ratio doesn't affect the value of a pool share.
        
        //2.If aleardy having liquidity in the pool
        //NOTE: Liquidity provider can only put 1 desired amount of tokens another token amount is calculated relative to the ratios in the pool
        //to get liquidity = min((_totalSupply*amt0/_reserves0),(_totalSupply*amt1/_reserves1))
        //the liquidity is backed by the reserves, so LP tokens mint to Liquidity provider
    //5.update the new balance of tokens to the pool by calling update(uint256 ,uint256 ) function
    
    function getReserves()private view returns(uint112 _resvs0,uint112 _resvs1){
        (_resvs0,_resvs1) = (reserves0,reserves1);
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

        update(balance0, balance1);

        emit Mint(to,amt0,amt1);

        return liquidity;
    }




    //Removing the liquidity from the pool
    //STEPs:
    //1.get the pool reserves of both token0 and token1
    //2.get the liquidity of LP tokens of the caller
    //3.calculating amt0 and amt1
    //4.burn the liquidity and transfer the proportional ratio of token0 and token1 to the liquidity provider
    //5._safeTransfer() function is used to transfer to the check it is valid transfer or not
    //6.update the reservs in the pool



    //Here we are checking the return value that is retruned from the transfer() function in the 
    //solmate ERC20 contract
    function _safeTransfer(address _token,address _to,uint256 _amt)private {
        (bool success,bytes memory data)=address(_token).call(abi.encodeWithSignature("transfer(address,uint256)"));
        require(success && data.length != 0,"transfer failed");
        IERC20(_token).transfer(_to,_amt);
    }


    function burn(address to)external lock returns(uint256 _amt0,uint256 _amt1){
        //get the reserves
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        //totalSupply of LP tokens
        uint256 _totalsupply=totalSupply;

        //Here the Router contract transfers liquidity to uniswapV2Pair contract 
        uint256 liquidity=balanceOf[address(this)];
        
        //Amount of liquidity to return
        uint256 amt0 = balance0*liquidity/_totalsupply;
        uint256 amt1 = balance1*liquidity/_totalsupply;

        require(amt0 > 0 && amt1 > 0,"insufficient liquidity to remove");

        _burn(to,liquidity);

         //This actually returns nothing, if transfer function fails to transfer
         //so, It is warapped into a _safeTrasfer() function
        // IERC20(token0).transfer(to, amt0);
        // IERC20(token1).transfer(to, amt1);

        _safeTransfer(token0,to,amt0);
        _safeTransfer(token1,to,amt1);

        //updating the balances of reserves to the pool
        balance0 -= amt0;
        balance1 -= amt1;

        update(balance0,balance1);

        emit Burn(to,liquidity);
        return (amt0,amt1);
    }


    //swapping tokens
    function swap(
        address _token,
        uint256 amountIn0,
        uint256 minAmountOut1,
        address to
        )
         external
          returns(
            uint256 _amtOut
            )
    {
        require(amountIn0 > 0 && minAmountOut1 > 0, "Insufficient funds");
        require(_token != address(0),"INVALID token address");
        (uint256 res0, uint256 res1) = getReserves();
        _amtOut = res0*amountIn0/res1;

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        require(balance0 * balance1 >= res0 * res1,"failed swap");

        require(_amtOut >= minAmountOut1,"insufficient output amount");
        IERC20(token1).transfer(to,_amtOut);
    }   
}