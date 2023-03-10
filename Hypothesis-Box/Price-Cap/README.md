# Hypothesis Box
### Smart Router with Price Cap


Implementation of the CEX-DEX smart router contract for testing hypothesis of saving gas and cutting irrelevant calculations by prioritising swap pools.

### Features

- Swap Pools Prioritization
- Gas Optimisation Algorithm
- MaxPrice Cap



### Tech

To execute a test swap follow the next steps:

1) ABI can be found [here](https://github.com/Fhneeeh/DEX-CEX-Arbitrage/blob/main/Hypothesis-Box/Price-Cap/ABI.txt)
2) Deployment Addresses can be found [here](https://github.com/Fhneeeh/DEX-CEX-Arbitrage/blob/main/Hypothesis-Box/Price-Cap/DeploymentAddresses.txt)
3) Need to give allowance for `tokenFrom` to be used by the smart-contract
4) Use `swapByPriority` function to execute a swap
5) If less than 3 pools/routers to be used - replace idle arguments with `0x0000000000000000000000000000000000000000` 
6) Set `maxPrice` as a 18-decimals digit
7) List all pools and routers in the order of proroty (from High to Low)


### Example

Buying WETH with USDC ([tx hash](https://polygonscan.com/tx/0xf8ba9af20a7ecbd8d13a26e376ee9789c8ecf26034b90684539902f8bf087a09))


```js
function swapByPriority(
        address tokenFrom,
        address tokenTo,
        uint256 size,
        uint256 maxPrice,
        address pool0,
        address router0,
        address pool1,
        address router1,
        address pool2,
        address router2
    ) external returns (bool);
```

```js
function swapByPriority(
        0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174,
        0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619,
        1000000,
        1403328000000000000000,
        0x45dDa9cb7c25131DF268515131f647d726f50608,
        0xE592427A0AEce92De3Edee1F18E0157C05861564,
        0x55CAaBB0d2b704FD0eF8192A7E35D8837e678207,
        0xf5b509bB0909a69B1c207E495f687a596C168E12,
        0x0387Dbd5E8504938edf4B38EaCBF77A1d0394a1B,
        0xC1e7dFE73E1598E3910EF4C7845B68A9Ab6F4c83
    );
```

If maxPrice is higher than swap price in `pool0`, it will go to `pool1` and if no success again to `pool2`. If none of the pools can satisfy the price cap, the transaction will revert with `Your maxPrice was not satisfied`.




