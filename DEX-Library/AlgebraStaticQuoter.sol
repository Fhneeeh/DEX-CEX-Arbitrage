// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import 'https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/PeripheryImmutableState.sol';
import 'https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/PoolAddress.sol';

import 'https://github.com/eden-network/uniswap-v3-static-quoter/blob/master/contracts/AlgebraQuoter/interfaces/IAlgebraStaticQuoter.sol';
import 'https://github.com/eden-network/uniswap-v3-static-quoter/blob/master/contracts/AlgebraQuoter/interfaces/IAlgebraFactory.sol';
import 'https://github.com/eden-network/uniswap-v3-static-quoter/blob/master/contracts/AlgebraQuoter/lib/PathNoFee.sol';
import 'https://github.com/eden-network/uniswap-v3-static-quoter/blob/master/contracts/AlgebraQuoter/AlgebraQuoterCore.sol';

contract AlgebraStaticQuoter is AlgebraQuoterCore {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    using PathNoFee for bytes;

    address immutable factory = 0x411b0fAcC3489691f28ad58c47006AF5E3Ab3A28;

    function getPool(
        address tokenA,
        address tokenB
    ) private view returns (address) {
        return IAlgebraFactory(factory).poolByPair(tokenA, tokenB);
    }

    function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
        public
        view
        returns (uint256 amountOut)
    {
        bool zeroForOne = params.tokenIn < params.tokenOut;
        address pool = getPool(params.tokenIn, params.tokenOut);
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
        returns (uint256 amountOut)
    {
        uint256 i = 0;
        while (true) {
            (address tokenIn, address tokenOut) = path.decodeFirstPool();
            // the outputs of prior swaps become the inputs to subsequent ones
            uint256 _amountOut =
                quoteExactInputSingle(
                    QuoteExactInputSingleParams({
                        tokenIn: tokenIn,
                        tokenOut: tokenOut,
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
