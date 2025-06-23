// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title LiquidityToken
 * @notice ERC-20 token representing liquidity shares in the pool.
 */
contract LiquidityToken is ERC20 {
    /// @notice Address of the SimpleSwap contract allowed to mint/burn tokens
    address public swapContract;

    /**
     * @notice Constructor sets the swap contract as the only minter/burner
     * @param name Token name
     * @param symbol Token symbol
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        swapContract = msg.sender;
    }

    /**
     * @dev Restricts function access to only the swap contract
     */
    modifier onlySwap() {
        require(msg.sender == swapContract, "Only SimpleSwap can call");
        _;
    }

    /**
     * @notice Mints liquidity tokens to a user
     * @param to Address receiving the tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint amount) external onlySwap {
        _mint(to, amount);
    }

    /**
     * @notice Burns liquidity tokens from a user
     * @param from Address whose tokens will be burned
     * @param amount Amount of tokens to burn
     */
    function burn(address from, uint amount) external onlySwap {
        _burn(from, amount);
    }
}

/**
 * @title SimpleSwap
 * @notice Simple Automated Market Maker (AMM) similar to Uniswap V2 without external dependencies.
 */
contract SimpleSwap {
    /// @notice Struct representing a liquidity pool
    struct Pool {
        uint reserveA;                     // Reserve of token A
        uint reserveB;                     // Reserve of token B
        LiquidityToken liquidityToken;     // LP token for the pair
    }

    /// @notice Parameters used to add liquidity
    struct AddLiquidityParams {
        address tokenA;        // First token address
        address tokenB;        // Second token address
        uint amountADesired;   // Desired amount of token A
        uint amountBDesired;   // Desired amount of token B
        uint amountAMin;       // Minimum accepted amount of token A
        uint amountBMin;       // Minimum accepted amount of token B
        address to;            // Recipient of liquidity tokens
    }

    /// @notice Mapping of token pairs to their liquidity pool
    mapping(address => mapping(address => Pool)) public pools;
    
    /**
     * @notice Adds liquidity to a token pair pool
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param amountADesired Desired amount of token A to add
     * @param amountBDesired Desired amount of token B to add
     * @param amountAMin Minimum amount of token A to accept
     * @param amountBMin Minimum amount of token B to accept
     * @param to Address receiving the liquidity tokens
     * @param deadline Unix timestamp after which the transaction reverts
     * @return amountA Final amount of token A added
     * @return amountB Final amount of token B added
     * @return liquidity Amount of liquidity tokens minted
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

        AddLiquidityParams memory params = AddLiquidityParams({
            tokenA: tokenA,
            tokenB: tokenB,
            amountADesired: amountADesired,
            amountBDesired: amountBDesired,
            amountAMin: amountAMin,
            amountBMin: amountBMin,
            to: to
        });

        (amountA, amountB, liquidity) = _addLiquidityInternal(params);
    }

    function _addLiquidityInternal(AddLiquidityParams memory p) internal
        returns (uint amountA, uint amountB, uint liquidity)
    {
        (address token0, address token1) = sortTokens(p.tokenA, p.tokenB);
        Pool storage pool = pools[token0][token1];

        if (address(pool.liquidityToken) == address(0)) {
            pool.liquidityToken = new LiquidityToken("Simple LP Token", "SLP");
        }

        uint reserve0 = pool.reserveA;
        uint reserve1 = pool.reserveB;

        (uint depositA, uint depositB) = _calculateLiquidityAmounts(
            p.amountADesired,
            p.amountBDesired,
            p.amountAMin,
            p.amountBMin,
            reserve0,
            reserve1
        );

        IERC20(p.tokenA).transferFrom(msg.sender, address(this), depositA);
        IERC20(p.tokenB).transferFrom(msg.sender, address(this), depositB);

        if (p.tokenA == token0) {
            pool.reserveA += depositA;
            pool.reserveB += depositB;
        } else {
            pool.reserveA += depositB;
            pool.reserveB += depositA;
        }

        uint totalSupply = pool.liquidityToken.totalSupply();
        liquidity = _calculateLiquidityTokens(depositA, depositB, reserve0, reserve1, totalSupply);
        pool.liquidityToken.mint(p.to, liquidity);

        amountA = depositA;
        amountB = depositB;
    }

    function _calculateLiquidityAmounts(
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        uint reserveA,
        uint reserveB
    )internal pure returns (uint amountA, uint amountB) {
        if (reserveA == 0 && reserveB == 0) {
            return (amountADesired, amountBDesired);
        }

        uint amountBOptimal = (amountADesired * reserveB) / reserveA;
        if (amountBOptimal <= amountBDesired) {
            require(amountBOptimal >= amountBMin, "B too low");
            return (amountADesired, amountBOptimal);
        } else {
            uint amountAOptimal = (amountBDesired * reserveA) / reserveB;
            require(amountAOptimal >= amountAMin, "A too low");
            return (amountAOptimal, amountBDesired);
        }
    }

    function _calculateLiquidityTokens(
        uint amountA,
        uint amountB,
        uint reserveA,
        uint reserveB,
        uint totalSupply
    ) internal pure returns (uint liquidity) {
        if (totalSupply == 0) {
            liquidity = sqrt(amountA * amountB);
        } else {
            liquidity = min(
                (amountA * totalSupply) / reserveA,
                (amountB * totalSupply) / reserveB
            );
        }
    }

     /**
     * @notice Removes liquidity from a pool and returns tokens to the user
     * @param tokenA First token of the pair
     * @param tokenB Second token of the pair
     * @param liquidity Amount of liquidity tokens to burn
     * @param amountAMin Minimum token A to receive
     * @param amountBMin Minimum token B to receive
     * @param to Address to receive the withdrawn tokens
     * @param deadline Unix timestamp after which the transaction reverts
     * @return amountA Amount of token A returned
     * @return amountB Amount of token B returned
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

        (address token0, address token1) = sortTokens(tokenA, tokenB);
        Pool storage pool = pools[token0][token1];
        require(address(pool.liquidityToken) != address(0), "Pool doesn't exist");

        uint reserve0 = pool.reserveA;
        uint reserve1 = pool.reserveB;

        uint totalSupply = pool.liquidityToken.totalSupply();

        pool.liquidityToken.burn(msg.sender, liquidity);

        amountA = (liquidity * reserve0) / totalSupply;
        amountB = (liquidity * reserve1) / totalSupply;

        require(amountA >= amountAMin, "A too low");
        require(amountB >= amountBMin, "B too low");

        if (tokenA == token0) {
            pool.reserveA -= amountA;
            pool.reserveB -= amountB;
        } else {
            pool.reserveA -= amountB;
            pool.reserveB -= amountA;
            (amountA, amountB) = (amountB, amountA); // flip amounts
        }

        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);
    }

    /**
     * @notice Swaps an exact amount of input token for as much as possible of the output token
     * @param amountIn Amount of input token to swap
     * @param amountOutMin Minimum amount of output token to receive
     * @param path Array with two addresses: [tokenIn, tokenOut]
     * @param to Recipient of the output tokens
     * @param deadline Unix timestamp after which the transaction reverts
     * @return amounts Array with [amountIn, amountOut]
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

        address tokenIn = path[0];
        address tokenOut = path[1];
        (address token0, address token1) = sortTokens(tokenIn, tokenOut);
        Pool storage pool = pools[token0][token1];
        require(address(pool.liquidityToken) != address(0), "Pool doesn't exist");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        (uint reserveIn, uint reserveOut) = tokenIn == token0
            ? (pool.reserveA, pool.reserveB)
            : (pool.reserveB, pool.reserveA);

        uint amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        require(amountOut >= amountOutMin, "Slippage too high");

        if (tokenIn == token0) {
            pool.reserveA += amountIn;
            pool.reserveB -= amountOut;
        } else {
            pool.reserveB += amountIn;
            pool.reserveA -= amountOut;
        }

        IERC20(tokenOut).transfer(to, amountOut);

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }

    /**
     * @notice Returns the price of tokenA in terms of tokenB
     * @param tokenA Input token
     * @param tokenB Output token
     * @return price Current price scaled by 1e18 (fixed point)
     */
    function getPrice(address tokenA, address tokenB) external view returns (uint price) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        Pool storage pool = pools[token0][token1];
        require(address(pool.liquidityToken) != address(0), "Pool doesn't exist");

        (uint reserveA, uint reserveB) = tokenA == token0
            ? (pool.reserveA, pool.reserveB)
            : (pool.reserveB, pool.reserveA);

        require(reserveA > 0, "Zero reserve");
        price = (reserveB * 1e18) / reserveA;
    }

    /**
     * @notice Calculates output amount of a swap given input and reserves
     * @param amountIn Amount of input tokens
     * @param reserveIn Input reserve
     * @param reserveOut Output reserve
     * @return amountOut Amount of output tokens received
     */    
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public pure returns (uint amountOut)
    {
        require(amountIn > 0, "Insufficient input");
        require(reserveIn > 0 && reserveOut > 0, "Invalid reserves");
        uint amountInWithFee = amountIn; // sin fee
        amountOut = (amountInWithFee * reserveOut) / (reserveIn + amountInWithFee);
    }

    /**
     * @notice Sorts token addresses to enforce canonical order
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return token0 The lower address
     * @return token1 The higher address
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        require(tokenA != tokenB, "Identical addresses");
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    /**
     * @notice Computes square root of x
     * @param x Input value
     * @return y Square root of x
     */
    function sqrt(uint x) internal pure returns (uint y) {
        if (x == 0) return 0;
        uint z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @notice Returns the minimum of two numbers
     * @param x First number
     * @param y Second number
     * @return Minimum of x and y
     */
    function min(uint x, uint y) internal pure returns (uint) {
        return x < y ? x : y;
    }
}