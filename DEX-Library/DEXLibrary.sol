// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.6 <0.8.8;

interface UniswapV3StaticQuoter {

    function quote(
        address poolAddress,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) external view returns (int256 amount0, int256 amount1);

}

interface KyberswapV3StaticQuoter {

    function quote(
        address poolAddress,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) external view returns (int256 amount0, int256 amount1);

}

interface QuickswapV3StaticQuoter {

    function quote(
        address poolAddress,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) external view returns (int256 amount0, int256 amount1);

}

interface UniswapV3Pool {

    function token0() external view returns (address);

}

interface KyberswapV3Pool{

    function token0() external view returns (address);

}

interface QuickswapV3Pool{

    function token0() external view returns (address);

}

interface UniswapV2Pool {

    function token0() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

}

interface UniswapV2Router {

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

}

interface UniswapV2RouterMM {

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 swapFee
    ) external pure returns (uint256 amountOut);

}

interface DODOPool {

    function _BASE_TOKEN_() external view returns (address);

    function querySellBase(address trader, uint256 payBaseAmount)
        external
        view
        returns (
            uint256 receiveQuoteAmount,
            uint256 mtFee,
            uint8 newRState,
            uint256 newBaseTarget
        );

    function querySellQuote(address trader, uint256 payQuoteAmount)
        external
        view
        returns (
            uint256 receiveBaseAmount,
            uint256 mtFee,
            uint8 newRState,
            uint256 newQuoteTarget
        );

}

contract DEXLibrary {

    address private constant KyberStaticQuoterAddress = 0xf8eeD2ec0a140a906c0cf591F4f120C4906593a0;
    address private constant UniswapV3StaticQuoterAddress = 0x6F5F6b54aBeceEc5377E581Ea250e286E0330882;
    address private constant AlgebraStaticQuoterAddress = 0xb1e88CaD40034c370840e1595193E6ba1D73c0ED;
    uint160 private constant minSqrtPriceLimitX96 = 4295343490;
    uint160 private constant maxSqrtPriceLimitX96 = 1461373636630004318706518188784493106690254656249;

    function UniV3getAmountOut(address tokenFrom, address pool, uint inputAmount) external view returns (uint) {

        int256 amountOut;

        if (tokenFrom == UniswapV3Pool(pool).token0()) {

            (,amountOut) = UniswapV3StaticQuoter(UniswapV3StaticQuoterAddress).quote(pool, true, int256(inputAmount), minSqrtPriceLimitX96);

            if (amountOut < 0) {
                amountOut = -amountOut;
            }

            return uint(amountOut);

        }

        else {

            (amountOut,) = UniswapV3StaticQuoter(UniswapV3StaticQuoterAddress).quote(pool, false, int256(inputAmount), maxSqrtPriceLimitX96);

            if (amountOut < 0) {
                amountOut = -amountOut;
            }

            return uint(amountOut);

        }

    }

    function KyberV3getAmountOut(address tokenFrom, address pool, uint inputAmount) external view returns (uint) {

        int256 amountOut;

        if (tokenFrom == KyberswapV3Pool(pool).token0()) {

            (,amountOut) = KyberswapV3StaticQuoter(KyberStaticQuoterAddress).quote(pool, true, int256(inputAmount), minSqrtPriceLimitX96);

            if (amountOut < 0) {
                amountOut = -amountOut;
            }

            return uint(amountOut);

        }

        else {

            (amountOut,) = KyberswapV3StaticQuoter(KyberStaticQuoterAddress).quote(pool, false, int256(inputAmount), maxSqrtPriceLimitX96);

            if (amountOut < 0) {
                amountOut = -amountOut;
            }

            return uint(amountOut);

        }

    }

    function QuickV3getAmountOut(address tokenFrom, address pool, uint inputAmount) external view returns (uint) {

        int256 amountOut;

        if (tokenFrom == QuickswapV3Pool(pool).token0()) {

            (,amountOut) = QuickswapV3StaticQuoter(AlgebraStaticQuoterAddress).quote(pool, true, int256(inputAmount), minSqrtPriceLimitX96);

            if (amountOut < 0) {
                amountOut = -amountOut;
            }

            return uint(amountOut);

        }

        else {

            (amountOut,) = QuickswapV3StaticQuoter(AlgebraStaticQuoterAddress).quote(pool, false, int256(inputAmount), maxSqrtPriceLimitX96);

            if (amountOut < 0) {
                amountOut = -amountOut;
            }

            return uint(amountOut);

        }

    }

    function UniV2getAmountOut(address tokenFrom, address pool, address router, uint inputAmount) external view returns (uint) {

        uint amountOut;
        uint reserve0;
        uint reserve1;

        if (tokenFrom != UniswapV2Pool(pool).token0()) {

            (reserve1, reserve0,) = UniswapV2Pool(pool).getReserves();

            if (router == 0x7E5E5957De93D00c352dF75159FbC37d5935f8bF) {
                amountOut = UniswapV2RouterMM(router).getAmountOut(uint(inputAmount), reserve0, reserve1, 17);
            }
            else {
                amountOut = UniswapV2Router(router).getAmountOut(uint(inputAmount), reserve0, reserve1);
            }
                        
            return amountOut;

        }

        else {

            (reserve0, reserve1,) = UniswapV2Pool(pool).getReserves();

            if (router == 0x7E5E5957De93D00c352dF75159FbC37d5935f8bF) {
                amountOut = UniswapV2RouterMM(router).getAmountOut(uint(inputAmount), reserve0, reserve1, 17);
            }
            else {
                amountOut = UniswapV2Router(router).getAmountOut(uint(inputAmount), reserve0, reserve1);
            }            
            
            return amountOut;              

        }

    }

    function DODOgetAmountOut(address tokenFrom, address pool, uint inputAmount) external view returns (uint){

        uint amountOut;

        if (tokenFrom == DODOPool(pool)._BASE_TOKEN_()) {

            (amountOut,,,) = DODOPool(pool).querySellBase(msg.sender,inputAmount);

        }

        else {

            (amountOut,,,) = DODOPool(pool).querySellQuote(msg.sender,inputAmount);

        }

        return amountOut;

    }

}
