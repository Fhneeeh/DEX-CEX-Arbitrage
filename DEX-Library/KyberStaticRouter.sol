// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import 'https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/PoolAddress.sol';
import 'https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/Path.sol';

import 'https://github.com/eden-network/uniswap-v3-static-quoter/blob/master/contracts/UniV3Quoter/interfaces/IUniswapV3StaticQuoter.sol';
import 'https://github.com/eden-network/uniswap-v3-static-quoter/blob/master/contracts/KyberQuoter/interfaces/IKyberFactory.sol';
import 'https://github.com/eden-network/uniswap-v3-static-quoter/blob/master/contracts/KyberQuoter/KyberQuoterCore.sol';

contract KyberStaticQuoter is IUniswapV3StaticQuoter, KyberQuoterCore {
    using SafeCast for uint256;
    using Path for bytes;

    address immutable factory = 0x411b0fAcC3489691f28ad58c47006AF5E3Ab3A28;

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (address) {
        return IKyberFactory(factory).getPool(tokenA, tokenB, fee);
    }

    function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
        public
        view
        override
        returns (uint256 amountOut)
    {
        bool zeroForOne = params.tokenIn < params.tokenOut;
        address pool = getPool(params.tokenIn, params.tokenOut, params.fee);
        require(pool != address(0), 'Pool not found');
        (int256 amount0, int256 amount1) = quote(
            pool,
            zeroForOne,
            params.amountIn.toInt256(),
            params.sqrtPriceLimitX96 == 0
                ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                : params.sqrtPriceLimitX96
        );

        return zeroForOne ? uint256(-amount1) : uint256(-amount0);
    }

    function quoteExactInput(bytes memory path, uint256 amountIn)
        public
        view
        override
        returns (uint256 amountOut)
    {
        uint256 i = 0;
        while (true) {
            (address tokenIn, address tokenOut, uint24 fee) = path.decodeFirstPool();

            // the outputs of prior swaps become the inputs to subsequent ones
            uint256 _amountOut =
                quoteExactInputSingle(
                    QuoteExactInputSingleParams({
                        tokenIn: tokenIn,
                        tokenOut: tokenOut,
                        fee: fee,
                        amountIn: amountIn,
                        sqrtPriceLimitX96: 0
                    })
                );

            amountIn = _amountOut;
            i++;

            // decide whether to continue or terminate
            if (path.hasMultiplePools()) {
                path = path.skipToken();
            } else {
                return amountIn;
            }
        }
    }
}
