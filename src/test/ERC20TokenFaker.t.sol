// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "solmate/tokens/ERC20.sol";
import "../FakeERC20.sol";
import "../ERC20TokenFaker.sol";

contract ERC20TokenFakerTest is
    DSTest,
    ERC20TokenFaker
{
    function testFakeERC20()
        public
    {
        ERC20 token = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        assertEq(token.balanceOf(address(this)), 0);

        fakeOutERC20(address(token))._setBalance(address(this), 10e18);
        assertEq(token.balanceOf(address(this)), 10e18);

        unfakeERC20(address(token));
        assertEq(token.balanceOf(address(this)), 0);
    }
}
