// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "solmate/tokens/ERC20.sol";
import "forge-std/stdlib.sol";

interface IUniswapV2Router
{
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        ERC20[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract UniswapV2StdLibTest is
    DSTest
{
    using stdStorage for StdStorage;
    StdStorage stdstore;

    function testUniswapV2Sell()
        public
    {
        IUniswapV2Router router = IUniswapV2Router(0xf164fC0Ec4E93095b804a4795bBe1e041497b92a);

        ERC20 sellToken = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        ERC20 buyToken  = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

        ERC20[] memory path = new ERC20[](2);
        path[0] = sellToken;
        path[1] = buyToken;

        uint256 amount = 1e18;
        sellToken.approve(address(router), amount);

        writeBalanceOf(sellToken, address(this), amount);

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

    function writeBalanceOf(ERC20 erc20, address who, uint256 balance)
        public
    {
        stdstore
            .target(address(erc20))
            .sig(erc20.balanceOf.selector)
            .with_key(who)
            .checked_write(balance);
    }
}
