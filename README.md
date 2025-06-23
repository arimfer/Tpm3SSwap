
# SimpleSwap

**SimpleSwap** is a lightweight Automated Market Maker (AMM) protocol inspired by Uniswap V2. It allows users to provide and withdraw liquidity, swap tokens, and calculate token prices using a constant product formula, without relying on any external Uniswap dependencies.

---

## 📦 Contracts

### `SimpleSwap.sol`
Implements the AMM logic.

### `LiquidityToken.sol`
ERC-20 token used to represent liquidity pool shares.

---

## 🧩 Features

- Add and remove liquidity from token pairs.
- Execute token swaps (1-to-1).
- Track and calculate token prices.
- Custom LP token per pair (`LiquidityToken`).
- On-chain reserve tracking.

---

## 🔧 Functions

### 🔹 `addLiquidity(...)`

Adds liquidity to a pool. If the pool does not exist, it is created.

```solidity
function addLiquidity(
  address tokenA,
  address tokenB,
  uint amountADesired,
  uint amountBDesired,
  uint amountAMin,
  uint amountBMin,
  address to,
  uint deadline
) external returns (uint amountA, uint amountB, uint liquidity);
```

**Returns:**
- `amountA`: Final amount of tokenA deposited.
- `amountB`: Final amount of tokenB deposited.
- `liquidity`: Amount of liquidity tokens minted.

---

### 🔹 `removeLiquidity(...)`

Removes liquidity from a pool and returns the underlying tokens.

```solidity
function removeLiquidity(
  address tokenA,
  address tokenB,
  uint liquidity,
  uint amountAMin,
  uint amountBMin,
  address to,
  uint deadline
) external returns (uint amountA, uint amountB);
```

**Returns:**
- `amountA`: Amount of tokenA returned.
- `amountB`: Amount of tokenB returned.

---

### 🔹 `swapExactTokensForTokens(...)`

Swaps an exact amount of one token for another.

```solidity
function swapExactTokensForTokens(
  uint amountIn,
  uint amountOutMin,
  address[] calldata path,
  address to,
  uint deadline
) external returns (uint[] memory amounts);
```

**Returns:**
- `amounts[0]`: Input token amount.
- `amounts[1]`: Output token amount received.

---

### 🔹 `getPrice(...)`

Returns the price of `tokenA` in terms of `tokenB`.

```solidity
function getPrice(address tokenA, address tokenB) external view returns (uint price);
```

---

### 🔹 `getAmountOut(...)`

Calculates how much output token is received for a given input.

```solidity
function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut);
```

---

## 🪙 LiquidityToken.sol

ERC-20 contract used as LP token. Only the `SimpleSwap` contract can mint or burn it.

### 🔸 `mint(address to, uint amount)`
Mints LP tokens to a user.

### 🔸 `burn(address from, uint amount)`
Burns LP tokens from a user.

---

## 🛠 Requirements

- Solidity ^0.8.0
- OpenZeppelin Contracts (`ERC20`, `IERC20`)
- Compatible with Remix, Hardhat or Foundry

---

## 🔐 Security Notes

- Tokens must be approved (`approve()`) before being transferred to the contract.
- No fees are charged by default; this can be modified in `getAmountOut()`.

---

## 📜 License

MIT © 2025
