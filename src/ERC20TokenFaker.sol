// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./interfaces/IVM.sol";
import "./FakeERC20.sol";

abstract contract ERC20TokenFaker
{

    FakeERC20 FAKE = new FakeERC20();
    IVm VM = IVm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function fakeOutERC20(address token)
        internal
        returns (FakeERC20 fakedToken)
    {
        fakeOut(token, address(FAKE).code);
        fakedToken = FakeERC20(payable(token));
    }

    function unfakeERC20(address token)
        internal
    {
        unfake(token);
    }

    function fakeOut(address orig, bytes memory code)
        private
    {
        // Move the original code to a new address
        address moved = movedAddress(orig);
        VM.etch(moved, orig.code);

        // Replace code with faked implementation
        VM.etch(orig, code);
    }

    function unfake(address addr)
        private
    {
        address moved = movedAddress(addr);
        if (addr.code.length != 0) {
            VM.etch(addr, moved.code);
        }
    }

    function movedAddress(address orig)
        private
        returns (address moved)
    {
        moved = address(uint160(address(orig)) + 1);
    }

}
