// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../IERC20Token.sol";
import "./ERC20TokenFaker.sol";

interface IUniswapV2Router
{
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        IERC20Token[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract UniswapV2Test is
    DSTest,
    ERC20TokenFaker
{

    function testUniswapV2Sell()
        public
    {
        IUniswapV2Router router = IUniswapV2Router(0xf164fC0Ec4E93095b804a4795bBe1e041497b92a);

        IERC20Token sellToken = IERC20Token(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        IERC20Token buyToken  = IERC20Token(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

        IERC20Token[] memory path = new IERC20Token[](2);
        path[0] = sellToken;
        path[1] = buyToken;

        uint256 amount = 1e18;
        sellToken.approve(address(router), amount);

        FakeERC20 fakeToken = fakeOutERC20(address(sellToken));
        fakeToken._setBalance(address(this), amount);

        assertEq(buyToken.balanceOf(address(this)), 0);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp+1
        );

        assertGt(buyToken.balanceOf(address(this)), 0);
        emit log_uint(buyToken.balanceOf(address(this)));
    }
}
