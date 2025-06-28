// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
/**
 * @title SimpleSwap
 * @notice A simple Automated Market Maker (AMM) similar to Uniswap V2 without external dependencies.
 * @dev Supports adding/removing liquidity and swapping between two ERC20 tokens.
 */
 contract SimpleSwap is ERC20 {

    constructor() ERC20("Liquidity Token", "LQT") {}

    /**
     * @notice Adds liquidity to the pool and mints LP tokens.
     * @param tokenA Address of token A.
     * @param tokenB Address of token B.
     * @param amountADesired Desired amount of token A to deposit.
     * @param amountBDesired Desired amount of token B to deposit.
     * @param amountAMin Minimum amount of token A to deposit.
     * @param amountBMin Minimum amount of token B to deposit.
     * @param to Address receiving the LP tokens.
     * @param deadline Expiration timestamp for the transaction.
     * @return amountA Actual amount of token A deposited.
     * @return amountB Actual amount of token B deposited.
     * @return liquidity Amount of LP tokens minted.
     */

    function addLiquidity(
            address tokenA,
            address tokenB,
            uint amountADesired,
            uint amountBDesired,
            uint amountAMin,
            uint amountBMin,
            address to,
            uint deadline
        ) external returns (uint amountA, uint amountB, uint liquidity) {
            require(block.timestamp <= deadline, "Deadline passed");
            
            liquidity = totalSupply();
            if (liquidity > 0) {
                uint256 l1 = (amountADesired * liquidity) / ERC20(tokenA).balanceOf(address(this));
                uint256 l2 = (amountBDesired * liquidity) / ERC20(tokenB).balanceOf(address(this));
                if(l1<l2){
                    amountA = amountADesired;
                    amountB = getPrice(tokenA, tokenB) * amountA;
                } else {
                    amountB = amountBDesired;
                    amountA = getPrice(tokenB, tokenA) * amountB;
                }
            } else {
                liquidity = amountADesired;
                amountA = amountADesired;
                amountB = amountBDesired;
            }

            require(amountAMin<=amountA);
            require(amountBMin<=amountB);
            ERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
            ERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
            _mint(to, liquidity);
        }

    /**
     * @notice Removes liquidity from the pool and burns LP tokens.
     * @param tokenA Address of token A.
     * @param tokenB Address of token B.
     * @param liquidity Amount of LP tokens to burn.
     * @param amountAMin Minimum amount of token A to receive.
     * @param amountBMin Minimum amount of token B to receive.
     * @param to Address receiving the withdrawn tokens.
     * @param deadline Expiration timestamp for the transaction.
     * @return amountA Amount of token A withdrawn.
     * @return amountB Amount of token B withdrawn.
     */
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB) {
        require(block.timestamp <= deadline, "Deadline passed");
        uint256 totaliquidity = totalSupply();

        amountA = liquidity * ERC20(tokenA).balanceOf(address(this)) / totaliquidity;
        amountB = liquidity * ERC20(tokenB).balanceOf(address(this)) / totaliquidity;
        
        require(amountAMin<=amountA);
        require(amountBMin<=amountB);

        _burn(msg.sender, liquidity);
        ERC20(tokenA).transfer(to, amountA);
        ERC20(tokenB).transfer(to, amountB);
    }

    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible.
     * @param amountIn Amount of input tokens to swap.
     * @param amountOutMin Minimum amount of output tokens to receive.
     * @param path Array of two addresses: [input token, output token].
     * @param to Address receiving the output tokens.
     * @param deadline Expiration timestamp for the transaction.
     * @return amounts Array with input and output amounts: [amountIn, amountOut].
     */
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(path.length == 2, "Only 2-token swap supported");
        require(block.timestamp <= deadline, "Deadline passed");
    
        ERC20 tokenA = ERC20(path[0]);
        ERC20 tokenB = ERC20(path[1]);
        uint256 amountOut = amountIn * tokenB.balanceOf(address(this)) / (amountIn + tokenA.balanceOf(address(this)));
        require(amountOut>=amountOutMin);
        tokenA.transferFrom(msg.sender, address(this), amountIn);
        tokenB.transfer(to, amountOut);

        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }

    /**
     * @notice Returns the price of token A in terms of token B (scaled by 1e18).
     * @param tokenA Address of token A.
     * @param tokenB Address of token B.
     * @return price Price of token A denominated in token B.
     */
    function getPrice(address tokenA, address tokenB) public view returns (uint price) {
        uint256 amount1 = ERC20(tokenA).balanceOf(address(this));
        uint256 amount2 = ERC20(tokenB).balanceOf(address(this));
        price = (amount2 * 1e18) / amount1;
    }        

    /**
     * @notice Calculates the expected output amount for a given input and reserves.
     * @param amountIn Amount of input tokens.
     * @param reserveIn Reserve of the input token.
     * @param reserveOut Reserve of the output token.
     * @return amountOut Expected amount of output tokens.
     */

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        external pure returns (uint amountOut)
    {   require(amountIn > 0, "Insufficient input");
        require(reserveIn > 0 && reserveOut > 0, "Invalid reserves");     
        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
    }
}