//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

// import "./interfaces/IuniswapV2Pair.sol";
// import "./interfaces/IERC20.sol";
// import "./interfaces/IuniswapV2Factory.sol";
import "./interfaces";

/**
 * @title Router contract
 * @author Naveen Pulamarasetti
 * @notice contract between endUser and core Contract
 * @dev not tested compeletly, under developing stage
 * @custom:experimental this is experimental contract of uniswapV2
 */
contract UniswapV2Router {
    ///factory address
    address public factory;

    constructor(address _factory) {
        factory = _factory;
    }

    ///@notice transfer function
    ///@dev safety check for ERC20 tokens tranfer/tranferFrom returns bool value , bascically transaction executes either true or false
    function _safeTransfer(address _token, address _to, uint256 _amt) internal {
        require(_amt > 0, "insuffiencent transfer");
        bool check = IERC20(_token).transferFrom(address(this), _to, _amt);
        require(check, "transfer failed");
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 desiredAmtTokenA,
        uint256 desiredAmtTokenB,
        uint256 amtAMin,
        uint256 amtBMin
    ) internal virtual returns (uint256 amtA, uint256 amtB) {
        ///if pair not exits yet create one
        if (IuniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IuniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        address contr_addr = IuniswapV2Factory(factory).getPair(tokenA, tokenB);
        (uint256 reservesA, uint256 reservesB) = IuniswapV2Pair(contr_addr)
            .getReserves();

        if (reservesA == 0 && reservesB == 0) {
            return (desiredAmtTokenA, desiredAmtTokenB);
        } else {
            //If all A tokens are considered , calculating the optimal tokens of B
            uint256 optTokenB = (reservesB * desiredAmtTokenA) / reservesA;
            if (reservesB >= optTokenB) {
                require(optTokenB >= amtBMin, "insufficent tokens of B");
                return (desiredAmtTokenA, optTokenB);
            } else {
                //If all B tokens are considered , calculating the optimal tokens of A
                uint256 optTokenA = (reservesA * desiredAmtTokenB) / reservesB;
                require(optTokenA >= amtAMin, "insufficent tokens of A");
                return (optTokenA, desiredAmtTokenB);
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
    ) external virtual returns (uint256 amtA, uint256 amtB, uint256 liquidity) {
        (amtA, amtB) = _addLiquidity(
            tokenA,
            tokenB,
            desiredAmtTokenA,
            desiredAmtTokenB,
            amtAMin,
            amtBMin
        );
        address contr_addr = IuniswapV2Factory(factory).getPair(tokenA, tokenB);

        _safeTransfer(tokenA, contr_addr, amtA);
        _safeTransfer(tokenB, contr_addr, amtB);

        liquidity = IuniswapV2Pair(contr_addr).mint(to);
    }

    ///@notice Removing Liquidity from the pool

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        address to,
        uint256 minAmtA,
        uint256 minAmtB
    ) public returns (uint256 amtA, uint256 amtB) {
        address contr_addr = IuniswapV2Factory(factory).getPair(tokenA, tokenB);
        // IuniswapV2Pair(contr_addr).transferFrom(msg.sender,contr_addr,liquidity);
        _safeTransfer(contr_addr, to, liquidity);
        (amtA, amtB) = IuniswapV2Pair(contr_addr).burn(to);
        require(amtA >= minAmtA, "Insufficient A token amount");
        require(amtB >= minAmtB, "Insufficinet B token amount");
    }

    //////////////////////////////SWAPPING TOKENS////////////////////////////////////////
    /**
     * @dev swapping tokens
     * @param tokenA is amtIn token contract
     * @param tokenB is amtOut token contract
     * @param amtIn is amount of tokens approved by the caller
     * @param minAmtOut is min amount of tokens to out
     * @return amtOut amount of tokens amtOut for ratio of amtIn
     * @dev tokenA is approved tokens to swap(caller should approve tokenA)
     * @dev tokenB is swapped tokens
     */
    function swap(
        address tokenA,
        address tokenB,
        uint256 amtIn,
        uint256 minAmtOut,
        address to
    ) external returns (uint256 amtOut) {
        require(
            tokenA != address(0) && tokenB != address(0),
            "uniswapV2: zero address"
        );
        require(amtIn > 0, "invalid amount");
        address contr_addr = IuniswapV2Factory(factory).getPair(tokenA, tokenB);
        amtOut = IuniswapV2Pair(contr_addr).swap(tokenB, amtIn, minAmtOut, to);
    }
}
