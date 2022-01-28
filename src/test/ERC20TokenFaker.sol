// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../FakeERC20.sol";
import "../IERC20Token.sol";

interface CheatCodes
{
    function etch(address who, bytes calldata code) external;
}

contract ERC20TokenFaker
{
    FakeERC20 fakeERC20 = new FakeERC20();
    CheatCodes cheatCodes = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function fakeOutERC20(address token)
        internal
        returns (FakeERC20 fakedToken)
    {
        // Move the original code to address+1
        address movedTokenAddress = address(uint160(address(token)) + 1);
        cheatCodes.etch(movedTokenAddress, address(token).code);

        // Replace token code with faked implementation
        cheatCodes.etch(address(token), address(fakeERC20).code);

        fakedToken = FakeERC20(payable(address(token)));
    }

    function unfakeERC20(address token)
        internal
    {
        address movedTokenAddress = address(uint160(address(token)) + 1);
        if (movedTokenAddress.code.length != 0) {
            cheatCodes.etch(token, movedTokenAddress.code);
        }
    }

}
