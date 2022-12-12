//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

///imports
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./uniswapV2ERC20.sol";
import "./libraries/Math.sol";
import "./libraries/UQ112x112.sol";

/**  What is libraries/UQ112x112 ? 
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

/**
 *@title UniswapV2Pair contract
 *@author naveen pulamarasetti
 *@notice creating the UniswapV1Pair contract which is low-level contract
 *@custom:experiment this is experimental contract
 */
contract UniswapV2Pair is UniswapV2ERC20 {
    using Math for uint256;
    using UQ112x112 for uint112;
    ///Minimum liquidity minted to 0 address
    uint256 public MINIMUM_LIQUIDITY = 1000;
    ///token0 address
    address public token0;
    ///token1 address
    address public token1;
    ///reserves of token0 in pool
    uint112 private reserves0;
    ///reserves of token1 in pool
    uint112 private reserves1;
    uint32 private blockTimestampLast;
    uint256 private unlocked = 1;

    ///events
    ///emits after the mint of LP tokens while adding liquidity
    event Mint(address to, uint256 amt0, uint256 amt1);
    ///emits after burn of LP tokens while removing liquidity
    event Burn(address to, uint256 LpTokens);
    ///emits after updated in the tokens reseves in the pool
    event Update(uint256 reserves0, uint256 reserves1);
    ///emits after swapped one token for other token
    event Swapped(address indexed to, uint256 amtIn, uint256 amtOut);

    ///modifiers
    ///mutex lock is using
    modifier lock() {
        require(unlocked == 1, "UniswapV2: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /**
     *@dev Constructor
     *@param _token0 of ERC20 token address
     *@param _token1 of ERc20 token address
     *@dev constructor sets the tokens address to use inside
     */
    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }

    ///////////////////////////SWAPING THE TOKENS////////////////////////////////////////
    /**
     * @dev swapping the tokens for one another
     * @param _token is the receiving token contract address
     * @param amountIn amount of tokens to in
     * @param minAmountOut minimum amount of out tokens
     * @param to receiver address
     * @return _amtOut require amount of tokens out for amountIn tokens
     */
    function swap(
        address _token,
        uint256 amountIn,
        uint256 minAmountOut,
        address to
    ) external lock returns (uint256 _amtOut) {
        require(amountIn > 0 && minAmountOut > 0, "Insufficient funds");
        require(_token != address(0), "INVALID token address");

        (uint256 res0, uint256 res1) = getReserves();

        if (_token == token1) {
            // _amtOut = (res1 * amountIn) / (res0 + amountIn);
            _amtOut = getAmtOut(amountIn, res1, res0);
        } else {
            // _amtOut = (res0 * amountIn) / (res1 + amountIn);
            _amtOut = getAmtOut(amountIn, res0, res1);
        }

        IERC20(token1).transfer(to, _amtOut);

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        require(balance0 * balance1 >= res0 * res1, "invalid uniswapV2 : k");
        require(_amtOut >= minAmountOut, "insufficient output amount");

        emit Swapped(to, amountIn, _amtOut);
    }

    ///////////////////Adding the liquidity to the pool//////////////////////////////////
    /** 
    * getting the reserves of the token0 and token1 of the pool
    * getting the amount of tokens token0 and token1 hold by the contract (i.e reserves 
    tokens + approved() tokens)
    * local variable liquidity is to hold the number of minted LP tokens and return it

    * Adding Liquidity divided into two branches :
    * ///////////////////1.If there is no liquidity in the pool//////////////////////////
    * LP tokens are calculated by the formula :
    * UniswapV2 people used geometric mean formula = sqrt(amt0 * amt1) - MINIMUM_LIQUIDITY
    (i.e 1000)
    * geometric mean ensures that intial liquidity ratio doesn't affect the value of a 
    pool share.
    * ////////////////2.If aleardy having liquidity in the pool//////////////////////////
    * NOTE: Liquidity provider can only put 1 desired amount of tokens another token amount
    is calculated relative to the ratios in the pool
    * to get liquidity = min((_totalSupply*amt0/_reserves0),(_totalSupply*amt1/_reserves1))
    * the liquidity is backed by the reserves, so LP tokens mint to Liquidity provider
    * update the new balance of tokens to the pool by calling update(uint256 ,uint256 ) fun
    *
    * @dev adding liquidity
    * @dev MINIMUM_LIQUIDITY tokens minting to 0 address
    * @param to is the to address of the liquidity provider
    * @return _liquidity  LP tokens sent back to the liquidity provider
    * 
    */
    function mint(address to) external lock returns (uint256 _liquidity) {
        (uint112 _reserves0, uint112 _reserves1) = getReserves();

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amt0 = balance0 - _reserves0;
        uint256 amt1 = balance1 - _reserves1;

        uint256 liquidity;

        uint256 _totalSupply = totalSupply;

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amt0 * amt1) - MINIMUM_LIQUIDITY;
        } else {
            liquidity = Math.min(
                ((_totalSupply * amt0) / _reserves0),
                ((_totalSupply * amt1) / _reserves1)
            );
        }

        require(liquidity < 0, "Insuffiecient LP tokens are minted ");

        _mint(to, liquidity);

        update(balance0, balance1);

        emit Mint(to, amt0, amt1);

        return liquidity;
    }

    ///////////////////Removing the liquidity from the pool//////////////////////////////
    /**
     *get the pool reserves of both token0 and token1
     *get the liquidity of LP tokens of the caller
     *calculating amt0 and amt1
     *burn the liquidity and transfer the proportional ratio of token0 and token1
      to the liquidity provider
     *_safeTransfer() function is used to transfer to the check it is valid transfer
      or not
     *update the reservs in the pool

     @dev Liquidity provider removing the liquidity from the pool with LP tokens
     @param to address of provider
     @return _amt0 amount of 0 tokens transfer to liquidity provider
     @return _amt1 amount of 1 tokens transfers to liquidity provider
     */

    function burn(
        address to
    ) external lock returns (uint256 _amt0, uint256 _amt1) {
        ///get the reserves
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        ///totalSupply of LP tokens
        uint256 _totalsupply = totalSupply;

        ///Here the Router contract transfers liquidity to uniswapV2Pair contract
        uint256 liquidity = balanceOf[address(this)];

        ///Amount of liquidity to return
        uint256 amt0 = (balance0 * liquidity) / _totalsupply;
        uint256 amt1 = (balance1 * liquidity) / _totalsupply;

        require(amt0 > 0 && amt1 > 0, "insufficient liquidity to remove");

        _burn(to, liquidity);

        _safeTransfer(token0, to, amt0);
        _safeTransfer(token1, to, amt1);

        balance0 = balance0 - amt0; //gas saving
        balance1 = balance1 - amt1; //gas saving

        update(balance0, balance1);

        emit Burn(to, liquidity);
        return (amt0, amt1);
    }

    /**
     * @dev used in swap , to calculate amount of tokens to out either 0 or 1 tokens
     * Used this formula :  delY = (Y * delX) / (X + delX);
     */
    function getAmtOut(
        uint256 amtIn,
        uint256 resA,
        uint256 resB
    ) internal pure returns (uint256 _amtOut) {
        _amtOut = (resA * amtIn) / (resB + amtIn);
    }

    /**
     * @dev updating reserves to the pool
     * @param _balance0 token0 amount
     * @param _balance1 token1 amount
     */
    function update(uint256 _balance0, uint256 _balance1) internal {
        require(
            _balance0 < type(uint112).max || _balance1 < type(uint112).max,
            "balance overflow"
        );
        reserves0 = uint112(_balance0);
        reserves1 = uint112(_balance1);
        blockTimestampLast = uint32(block.timestamp);

        emit Update(reserves0, reserves1);
    }

    /**
     * @dev total reserves in the pool
     * @return _resvs0 token0 reserves
     * @return _resvs1 token1 reserves
     */
    function getReserves()
        private
        view
        returns (uint112 _resvs0, uint112 _resvs1)
    {
        (_resvs0, _resvs1) = (reserves0, reserves1);
    }

    /**
     * @dev checking return value of transfer() function in the solmate ERC20 contract
     * @param _token address of the token contract
     * @param _to whom to transfer the tokens
     * @param _amt amount of tokens to transfer
     */
    function _safeTransfer(address _token, address _to, uint256 _amt) private {
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSignature("transfer(address,uint256)")
        );
        require(success && data.length != 0, "transfer failed");
        IERC20(_token).transfer(_to, _amt);
    }
}
