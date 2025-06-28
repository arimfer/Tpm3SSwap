# SimpleSwap

A minimal **Automated Market Maker (AMM)** smart contract inspired by Uniswap V2, implemented in Solidity without external on-chain dependencies (except OpenZeppelin ERC20 utilities).

## 🚀 Overview

**SimpleSwap** allows users to:

- Add liquidity to a token pair pool and receive LP (Liquidity Provider) tokens.
- Remove liquidity and receive underlying tokens.
- Swap tokens using a constant product formula (`x * y = k`), without fees.
- Query pool prices and expected output amounts.

The contract issues an ERC20 token as the LP token ("Liquidity Token" with symbol "LQT").

---

## ⚖️ Constant Product Formula

The AMM maintains the invariant:

```
x * y = k
```

Where:

- `x` = reserve of token A
- `y` = reserve of token B
- `k` = constant

This ensures that after each swap, liquidity remains balanced without explicit order books.

---

## 🛠️ Deployment

```bash
# Install dependencies
npm install

# Compile
npx hardhat compile

# Deploy (example)
npx hardhat run scripts/deploy.js --network <network_name>
```

---

## 💧 Liquidity Functions

### `addLiquidity(...)`

Adds liquidity to the pool.

**Parameters:**

- `tokenA`, `tokenB`: ERC20 token addresses.
- `amountADesired`, `amountBDesired`: desired amounts to deposit.
- `amountAMin`, `amountBMin`: minimum amounts to accept (slippage protection).
- `to`: address receiving LP tokens.
- `deadline`: timestamp after which the transaction is invalid.

**Returns:**

- `amountA`: actual amount of token A deposited.
- `amountB`: actual amount of token B deposited.
- `liquidity`: amount of LP tokens minted.

---

### `removeLiquidity(...)`

Removes liquidity and burns LP tokens.

**Parameters:**

- `tokenA`, `tokenB`: ERC20 token addresses.
- `liquidity`: amount of LP tokens to burn.
- `amountAMin`, `amountBMin`: minimum amounts to receive.
- `to`: address receiving tokens.
- `deadline`: timestamp after which the transaction is invalid.

**Returns:**

- `amountA`: amount of token A returned.
- `amountB`: amount of token B returned.

---

## 🔄 Swap Function

### `swapExactTokensForTokens(...)`

Swaps an exact amount of input tokens for as many output tokens as possible.

**Parameters:**

- `amountIn`: exact amount of input tokens.
- `amountOutMin`: minimum acceptable amount of output tokens.
- `path`: token address array `[tokenIn, tokenOut]`.
- `to`: recipient address.
- `deadline`: timestamp after which the transaction is invalid.

**Returns:**

- `amounts`: array `[amountIn, amountOut]`.

---

## 📈 View Functions

### `getPrice(tokenA, tokenB)`

Returns the price of `tokenA` denominated in `tokenB`, scaled by `1e18`.

---

### `getAmountOut(amountIn, reserveIn, reserveOut)`

Helper function to calculate the expected output amount for a given input and reserves, using the formula:

```
amountOut = (amountIn * reserveOut) / (reserveIn + amountIn)
```

---

## ⚡ LP Token

- Name: **Liquidity Token**
- Symbol: **LQT**
- Follows standard ERC20 behavior.

When you provide liquidity, you receive LP tokens representing your pool share. When you remove liquidity, these tokens are burned.

---

## ✅ Security Notes

- Uses `SafeERC20` from OpenZeppelin for safe token transfers.
- Reverts if minimum amounts or deadlines are not respected.
- **⚠️ No swap fees are included (0% fee).** In a production environment, you may want to add a fee mechanism.

---

## 🧪 Testing

We recommend testing with Hardhat or Foundry. Example tests:

- Provide and remove liquidity with different ratios.
- Perform swaps and validate output amounts.
- Check price calculation and invariant maintenance (`x * y = k`).

---

## 💬 License

[MIT](LICENSE)

---

## 🤝 Contributions

Feel free to open issues or pull requests to improve the contract or add features (e.g., fees, multi-token paths, advanced math).

---

## 🌐 Author

Built with ❤️ for educational purposes. Inspired by [Uniswap V2](https://uniswap.org/).

---

### Example

```solidity
// Add liquidity
simpleSwap.addLiquidity(tokenA, tokenB, 1000 ether, 2000 ether, 900 ether, 1800 ether, msg.sender, block.timestamp + 600);

// Swap
address[] memory path = new address[](2);
path[0] = address(tokenA);
path[1] = address(tokenB);
simpleSwap.swapExactTokensForTokens(100 ether, 190 ether, path, msg.sender, block.timestamp + 600);
```

---

