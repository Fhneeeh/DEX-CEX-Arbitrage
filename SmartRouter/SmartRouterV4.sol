// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.6 <0.8.8;
pragma abicoder v2;

interface ERC20 {

    function decimals() external view returns (uint8);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

}

interface DEXLibrary {

    function DODOgetAmountOut(
        address tokenFrom,
        address pool,
        uint256 inputAmount
    ) external view returns (uint256);

    function KyberV3getAmountOut(
        address tokenFrom,
        address pool,
        uint256 inputAmount
    ) external view returns (uint256);

    function QuickV3getAmountOut(
        address tokenFrom,
        address pool,
        uint256 inputAmount
    ) external view returns (uint256);

    function UniV2getAmountOut(
        address tokenFrom,
        address pool,
        address router,
        uint256 inputAmount
    ) external view returns (uint256);

    function UniV3getAmountOut(
        address tokenFrom,
        address pool,
        uint256 inputAmount
    ) external view returns (uint256);

}

interface UniswapV3Router {

    function exactInputSingle(ISwapRouter.ExactInputSingleParams memory params) external returns (uint256 amountOut);

}

interface ISwapRouter {
   
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

}

interface UniswapV2Router {

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

}

interface UniswapV3Pool {

    function fee() external view returns (uint24);

}

interface UniswapV2Factory {

    function getPair(address, address) external view returns (address);

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

interface QuickswapV3Router {

    function exactInputSingle(QSwapRouter.ExactInputSingleParams memory params) external returns (uint256 amountOut);

}

interface QSwapRouter {
   
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

}

interface KyberswapV3Pool {

    function swapFeeUnits() external view returns (uint24);

}

interface KyberswapV3Router {

    function factory() external view returns (address);

    function swapExactInputSingle(KSwapRouter.ExactInputSingleParams memory params)
        external
        payable
        returns (uint256 amountOut);

}

interface KSwapRouter {
   
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

}

interface DODOPool {

    function _BASE_TOKEN_() external view returns (address);

}

interface DodoRouter {

    function dodoSwapV2TokenToToken(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool,
        uint256 deadLine
    ) external returns (uint256 returnAmount);

}

interface AAVEPool {

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

}

contract SmartRouterV4 {

    event amountReceipt(uint[]);
    
    address private constant Owner = 0xbBcdE02c6c6b5e0aD7D9c34CB1a2786e8F7F5193;

    address private constant UniV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address private constant QuickV3Router = 0xf5b509bB0909a69B1c207E495f687a596C168E12;

    address private constant KyberV3Router = 0xC1e7dFE73E1598E3910EF4C7845B68A9Ab6F4c83;

    address private constant DodoV2Router = 0xa222e6a71D1A1Dd5F279805fbe38d5329C1d0e70;

    address private constant DodoV2Approve = 0x6D310348d5c12009854DFCf72e0DF9027e8cb4f4;

    address private constant AaveV3Pool = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;

    address private constant QuickV2Router = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    address private constant QuickV2Factory = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;

    address private constant UniswapV3MathLibrary = 0x4b3654F5390796dF1d9586047Ea2147212a88582;

    address private constant DEXLibraryAddress = 0x7537F9d63e1C7f295832a7455dD6aBDa4b041bdA;


    function withdrawToken(address tokenAddress) public {

        require(msg.sender == Owner, "Only Owner can do this!");

        ERC20(tokenAddress).transfer(Owner, ERC20(tokenAddress).balanceOf(address(this)));

    }

    function executeSwap(address tokenFrom, address tokenTo, address[] memory routers, address[] memory pools, uint inputAmount) public {

        (address bestRouter, address bestPool, uint[] memory amountOutList) = findBestRoute(tokenFrom, routers, pools, inputAmount);

        ERC20(tokenFrom).transferFrom(msg.sender,address(this),inputAmount);

        ERC20(tokenFrom).approve(bestRouter,inputAmount);

        if (bestRouter == UniV3Router) {

            UniV3Swap(tokenFrom, tokenTo, bestRouter, bestPool, inputAmount);

        }

        else if (bestRouter == QuickV3Router) {

            QuickV3Swap(tokenFrom, tokenTo, bestRouter, inputAmount);

        }

        else if (bestRouter == KyberV3Router) {

            KyberV3Swap(tokenFrom, tokenTo, bestRouter, bestPool, inputAmount);

        }

        else if (bestRouter == DodoV2Router) {

            DODOSwap(tokenFrom, tokenTo, bestRouter, bestPool, inputAmount);

        }

        else {

            UniV2Swap(tokenFrom, tokenTo, bestRouter, inputAmount);

        }

        ERC20(tokenTo).transfer(msg.sender,ERC20(tokenTo).balanceOf(address(this)));

        emit amountReceipt(amountOutList);

    }

    function UniV3Swap(address tokenFrom, address tokenTo, address router, address pool, uint inputAmount) public {

        uint24 fee = UniswapV3Pool(pool).fee();

        UniswapV3Router(router).exactInputSingle(ISwapRouter.ExactInputSingleParams(tokenFrom,tokenTo,fee,address(this),block.timestamp + 6000, inputAmount,0,0));

    }

    function QuickV3Swap(address tokenFrom, address tokenTo, address router, uint inputAmount) public {

        QuickswapV3Router(router).exactInputSingle(QSwapRouter.ExactInputSingleParams(tokenFrom,tokenTo,address(this),block.timestamp + 6000, inputAmount,0,0));

    }

    function KyberV3Swap(address tokenFrom, address tokenTo, address router, address pool, uint inputAmount) public {

        uint24 fee = KyberswapV3Pool(pool).swapFeeUnits();

        KyberswapV3Router(router).swapExactInputSingle(KSwapRouter.ExactInputSingleParams(tokenFrom,tokenTo,fee,address(this),block.timestamp + 6000, inputAmount,0,0));

    }

    function DODOSwap(address tokenFrom, address tokenTo, address router, address pool, uint inputAmount) public {

        ERC20(tokenFrom).approve(DodoV2Approve,inputAmount);

        address[] memory pools = new address[](1);
        pools[0] = pool;
        bool something;

        if (tokenFrom == DODOPool(pool)._BASE_TOKEN_()) {

            DodoRouter(router).dodoSwapV2TokenToToken(tokenFrom,tokenTo,inputAmount,1,pools,0,something, block.timestamp + 6000);

        }

    }

    function UniV2Swap(address tokenFrom, address tokenTo, address router, uint inputAmount) public {

        address[] memory path = new address[](2);
        path[0] = tokenFrom;
        path[1] = tokenTo;

        UniswapV2Router(router).swapExactTokensForTokens(inputAmount,0,path,address(this),block.timestamp + 6000);

    }

    function findBestRoute(address tokenFrom, address[] memory routers, address[] memory pools, uint inputAmount) public view returns (address,address,uint[] memory) {

        uint[] memory amountOutList = new uint[](routers.length);

        uint amountOut;
        uint bestAmountOut = 0;
        address bestRouter;
        address bestPool;

        for (uint i = 0; i < routers.length; i++) {

            if (routers[i] == UniV3Router) {
                amountOut = DEXLibrary(DEXLibraryAddress).UniV3getAmountOut(tokenFrom, pools[i], inputAmount);
            }

            else if (routers[i] == QuickV3Router) {
                amountOut = DEXLibrary(DEXLibraryAddress).QuickV3getAmountOut(tokenFrom, pools[i], inputAmount);
            }

            else if (routers[i] == KyberV3Router) {
                amountOut = DEXLibrary(DEXLibraryAddress).KyberV3getAmountOut(tokenFrom, pools[i], inputAmount);
            }

            else if (routers[i] == DodoV2Router) {
                amountOut = DEXLibrary(DEXLibraryAddress).DODOgetAmountOut(tokenFrom, pools[i], inputAmount);
            }

            else {
                amountOut = DEXLibrary(DEXLibraryAddress).UniV2getAmountOut(tokenFrom, pools[i], routers[i], inputAmount);
            }

            amountOutList[i] = amountOut;

            if (amountOut > bestAmountOut) {
                bestAmountOut = amountOut;
                bestRouter = routers[i];
                bestPool = pools[i];
            }

        }

        return (bestRouter, bestPool, amountOutList);

    }

    function executeBorrowAndSwap(address tokenToSupply, address tokenToBorrowAndSwap, address[] memory routers, address[] memory pools, uint inputToBorrowAndSwap, uint percentageToBorrow) public {

        uint amountToSupply = getAmoutToSupply(tokenToSupply, tokenToBorrowAndSwap, inputToBorrowAndSwap, percentageToBorrow);

        ERC20(tokenToSupply).transferFrom(msg.sender,address(this),amountToSupply);

        ERC20(tokenToSupply).approve(AaveV3Pool,amountToSupply);

        AAVEPool(AaveV3Pool).supply(tokenToSupply,amountToSupply,msg.sender,0);

        AAVEPool(AaveV3Pool).borrow(tokenToBorrowAndSwap, inputToBorrowAndSwap, 2, 0, msg.sender);

        (address bestRouter, address bestPool, uint[] memory amountOutList) = findBestRoute(tokenToBorrowAndSwap, routers, pools, inputToBorrowAndSwap);

        ERC20(tokenToBorrowAndSwap).approve(bestRouter,inputToBorrowAndSwap);

        if (bestRouter == UniV3Router) {

            UniV3Swap(tokenToBorrowAndSwap, tokenToSupply, bestRouter, bestPool, inputToBorrowAndSwap);

        }

        else if (bestRouter == QuickV3Router) {

            QuickV3Swap(tokenToBorrowAndSwap, tokenToSupply, bestRouter, inputToBorrowAndSwap);

        }

        else if (bestRouter == KyberV3Router) {

            KyberV3Swap(tokenToBorrowAndSwap, tokenToSupply, bestRouter, bestPool, inputToBorrowAndSwap);

        }

        else if (bestRouter == DodoV2Router) {

            DODOSwap(tokenToBorrowAndSwap, tokenToSupply, bestRouter, bestPool, inputToBorrowAndSwap);

        }

        else {

            UniV2Swap(tokenToBorrowAndSwap, tokenToSupply, bestRouter, inputToBorrowAndSwap);

        }

        ERC20(tokenToSupply).transfer(msg.sender,ERC20(tokenToSupply).balanceOf(address(this)));

        emit amountReceipt(amountOutList);



    }

    function getAmoutToSupply(address tokenToSupply, address tokenToBorrowAndSwap, uint inputToBorrowAndSwap, uint percentageToBorrow) public view returns (uint) {

        address pool = UniswapV2Factory(QuickV2Factory).getPair(tokenToSupply, tokenToBorrowAndSwap);

        uint reserve0;
        uint reserve1;

        uint outputAmount;

        if (tokenToBorrowAndSwap != UniswapV2Pool(pool).token0()) {

            (reserve1, reserve0,) = UniswapV2Pool(pool).getReserves();
            
            outputAmount = UniswapV2Router(QuickV2Router).getAmountOut(inputToBorrowAndSwap, reserve0, reserve1);
            
        }

        else {

            (reserve0, reserve1,) = UniswapV2Pool(pool).getReserves();
            
            outputAmount = UniswapV2Router(QuickV2Router).getAmountOut(inputToBorrowAndSwap, reserve0, reserve1);

        }

        uint ammountToSupply = (outputAmount * 100) / percentageToBorrow;
        
        return ammountToSupply;

    }

}
