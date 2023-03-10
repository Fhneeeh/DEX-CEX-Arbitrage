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

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function totalSupply() external view returns (uint256);

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

contract SmartRouterWithPriceCap {

    address private constant Owner = 0xbBcdE02c6c6b5e0aD7D9c34CB1a2786e8F7F5193;

    address private constant UniV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address private constant QuickV3Router = 0xf5b509bB0909a69B1c207E495f687a596C168E12;

    address private constant KyberV3Router = 0xC1e7dFE73E1598E3910EF4C7845B68A9Ab6F4c83;

    address private constant DEXLibraryAddress = 0x7537F9d63e1C7f295832a7455dD6aBDa4b041bdA;

    function swapByPriority(address tokenFrom, address tokenTo, uint size, uint maxPrice, address pool0, address router0, address pool1, address router1, address pool2, address router2) external returns (bool) {

        if (calculatePrice(tokenFrom,tokenTo,size,pool0,router0) < maxPrice) {

            executeSwap(tokenFrom,tokenTo,router0,pool0,size);

            return true;

        }

        if (pool1 != address(0)) {

            if (calculatePrice(tokenFrom,tokenTo,size,pool1,router1) < maxPrice) {

                executeSwap(tokenFrom,tokenTo,router1,pool1,size);

                return true;

            }

        }

        if (pool2 != address(0)) {

           if (calculatePrice(tokenFrom,tokenTo,size,pool2,router2) < maxPrice) {

                executeSwap(tokenFrom,tokenTo,router2,pool2,size);

                return true;

            } 

        }

        revert("Your maxPrice was not satisfied");

    }

    function calculatePrice(address tokenFrom, address tokenTo, uint inputAmount, address pool, address router) public view returns (uint){

        uint amountOut;

        if (router == UniV3Router) {
            amountOut = DEXLibrary(DEXLibraryAddress).UniV3getAmountOut(tokenFrom, pool, inputAmount);
        }

        else if (router == QuickV3Router) {
            amountOut = DEXLibrary(DEXLibraryAddress).QuickV3getAmountOut(tokenFrom, pool, inputAmount);
        }

        else if (router == KyberV3Router) {
            amountOut = DEXLibrary(DEXLibraryAddress).KyberV3getAmountOut(tokenFrom, pool, inputAmount);
        }

        else {
            amountOut = DEXLibrary(DEXLibraryAddress).UniV2getAmountOut(tokenFrom, pool, router, inputAmount);
        }

        return (inputAmount * 10 **(18-ERC20(tokenFrom).decimals())) * 10**18 / (amountOut * 10**(18-ERC20(tokenTo).decimals()));

    }

    function executeSwap(address tokenFrom, address tokenTo, address router, address pool, uint inputAmount) public {

        ERC20(tokenFrom).transferFrom(msg.sender,address(this),inputAmount);

        if (ERC20(tokenFrom).allowance(address(this),router) < inputAmount) {

            ERC20(tokenFrom).approve(router, ERC20(tokenFrom).totalSupply());

        }
        
        if (router == UniV3Router) {

            uint24 fee = UniswapV3Pool(pool).fee();
            UniswapV3Router(router).exactInputSingle(ISwapRouter.ExactInputSingleParams(tokenFrom,tokenTo,fee,address(this),block.timestamp + 6000, inputAmount,0,0));
        
        }

        else if (router == QuickV3Router) {

            QuickswapV3Router(router).exactInputSingle(QSwapRouter.ExactInputSingleParams(tokenFrom,tokenTo,address(this),block.timestamp + 6000, inputAmount,0,0));

        }

        else if (router == KyberV3Router) {

            uint24 fee = KyberswapV3Pool(pool).swapFeeUnits();
            KyberswapV3Router(router).swapExactInputSingle(KSwapRouter.ExactInputSingleParams(tokenFrom,tokenTo,fee,address(this),block.timestamp + 6000, inputAmount,0,0));
        
        }

        else {

            address[] memory path = new address[](2);
            path[0] = tokenFrom;
            path[1] = tokenTo;

            UniswapV2Router(router).swapExactTokensForTokens(inputAmount,0,path,address(this),block.timestamp + 6000);
        
        }

        ERC20(tokenTo).transfer(msg.sender,ERC20(tokenTo).balanceOf(address(this)));

    }

    function withdrawToken(address tokenAddress) public {

        require(msg.sender == Owner, "Only Owner can do this!");

        ERC20(tokenAddress).transfer(Owner, ERC20(tokenAddress).balanceOf(address(this)));

    }

}
