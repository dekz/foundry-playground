// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

interface IERC20 {
    function allowance(address owner, address spender) external returns (uint256);
    function balanceOf(address owner) external returns (uint256);
}

contract FakeERC20 {

    struct ShadowedAmount {
        bool isShadowed;
        uint256 lastTrueAmount;
        uint256 shadowedAmount;
    }

    struct Storage {
        mapping(address=>ShadowedAmount) shadowedBalances;
        mapping(address=>mapping(address=>ShadowedAmount)) shadowedAllowances;
    }

    bytes32 private constant STORAGE_SLOT = 0x64fd48372774b9637ace5c8c7a951f04ea13c793935207f2eada5382a0ec82cb;

    receive() external payable {}

    fallback() payable external {
        bytes memory r = _forwardCallToImpl();
        assembly { return(add(r, 32), mload(r)) }
    }

    function balanceOf(address owner)
        external
        /* view */
        returns (uint256 balance)
    {
        ShadowedAmount memory sBal = _getSyncedBalance(owner);
        return sBal.shadowedAmount;
    }

    function allowance(address owner, address spender)
        external
        /* view */
        returns (uint256 allowance_)
    {
        ShadowedAmount memory sBal = _getSyncedAllowance(owner, spender);
        return sBal.shadowedAmount;
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        returns (bool success)
    {
        _updateAllowance(from, amount);
        success = _transferFromInternal(from, to, amount);
    }


    function transfer(address to, uint256 amount)
        external
        returns (bool success)
    {
        success = _transferFromInternal(msg.sender, to, amount);
    }

    function approve(address spender, uint256 amount)
        external
        returns (bool)
    {
        ShadowedAmount memory sAllowance = _getSyncedAllowance(msg.sender, spender);

        sAllowance.shadowedAmount = amount;
        _writeSyncedAllowance(msg.sender, spender, sAllowance);

        return true;
    }

    function _setBalance(address owner, uint256 amount)
        public
        returns (uint256 newBalance)
    {
        ShadowedAmount memory sBal = _getSyncedBalance(owner);
        sBal.shadowedAmount = amount;
        _writeSyncedBalance(owner, sBal);
        newBalance = _getStorage().shadowedBalances[owner].shadowedAmount;
    }


    function _getSyncedAllowance(address owner, address spender)
        private
        /* view */
        returns (ShadowedAmount memory sAllowance)
    {
        uint256 trueAmount = abi.decode(
            _forwardCallToImpl(abi.encodeWithSelector(
                IERC20.allowance.selector,
                owner,
                spender
            )),
            (uint256)
        );
        // We only want to measure the cost of the underlying token storage lookup
        // Not including the excess overhead of our shadow lookup
        sAllowance = _getStorage().shadowedAllowances[owner][spender];
        _syncShadowedAmount(sAllowance, trueAmount);
    }

    function _getSyncedBalance(address owner)
        private
        returns (ShadowedAmount memory sBal)
    {
        uint256 trueAmount = abi.decode(
            _forwardCallToImpl(abi.encodeWithSelector(
                IERC20.balanceOf.selector,
                owner
            )),
            (uint256)
        );
        // We only want to measure the cost of the underlying token storage lookup
        // Not including the excess overhead of our shadow lookup
        sBal = _getStorage().shadowedBalances[owner];
        _syncShadowedAmount(sBal, trueAmount);
    }

    function _syncShadowedAmount(ShadowedAmount memory sAmount, uint256 trueAmount)
        private
        pure
    {
        if (!sAmount.isShadowed) {
            sAmount.isShadowed = true;
            sAmount.shadowedAmount = trueAmount;
        } else {
            // Detect balance changes that can occur from outside of ERC20
            // functions.
            if (sAmount.lastTrueAmount > trueAmount) {
                sAmount.shadowedAmount = _sub(
                    sAmount.lastTrueAmount,
                    sAmount.lastTrueAmount - trueAmount,
                    'FakeERC20/SHADOW_ADJUSTMENT_UNDERFLOW'
                );
            } else if (sAmount.lastTrueAmount < trueAmount) {
                sAmount.shadowedAmount = _add(
                    sAmount.lastTrueAmount,
                    trueAmount - sAmount.lastTrueAmount,
                    'FakeERC20/SHADOW_ADJUSTMENT_OVERFLOW'
                );
            }
        }
        sAmount.lastTrueAmount = trueAmount;
    }

    function _writeSyncedBalance(address owner, ShadowedAmount memory sBal)
        private
    {
        _getStorage().shadowedBalances[owner] = sBal;
    }

    function _writeSyncedAllowance(
        address owner,
        address spender,
        ShadowedAmount memory sAllowance
    )
        private
    {
        _getStorage().shadowedAllowances[owner][spender] = sAllowance;
    }

    function _getStorage() private pure returns (Storage storage st) {
        bytes32 slot = STORAGE_SLOT;
        assembly { st.slot := slot }
    }

    function _getOriginalImplementationAddress()
        private
        view
        returns (address impl)
    {
        return address(uint160(address(this)) + 1);
    }

    function _forwardCallToImpl()
        private
        returns (bytes memory resultData)
    {
        bool success;
        (success, resultData) =
            _getOriginalImplementationAddress().delegatecall(msg.data);
        if (!success) {
            assembly { revert(add(resultData, 32), mload(resultData)) }
        }
    }

    function _forwardCallToImpl(bytes memory callData)
        private
        returns (bytes memory resultData)
    {
        bool success;
        (success, resultData) =
            _getOriginalImplementationAddress().delegatecall(callData);
        if (!success) {
            assembly { revert(add(resultData, 32), mload(resultData)) }
        }
    }

    function _transferFromInternal(address from, address to, uint256 amount)
        internal
        returns (bool)
    {
        ShadowedAmount memory sFromBal;
        ShadowedAmount memory sToBal;

        sFromBal = _getSyncedBalance(from);
        sFromBal.shadowedAmount = _sub(
            sFromBal.shadowedAmount,
            amount,
            'FakeERC20/BALANCE_UNDERFLOW'
        );
        _writeSyncedBalance(from, sFromBal);

        sToBal = _getSyncedBalance(to);
        sToBal.shadowedAmount = _add(
            sToBal.shadowedAmount,
            amount,
            'FakeERC20/BALANCE_OVERFLOW'
        );
        _writeSyncedBalance(to, sToBal);

        return true;
    }

    function _updateAllowance(address from, uint256 amount)
        internal
    {
        ShadowedAmount memory sAllowance = _getSyncedAllowance(from, msg.sender);
        if (from != msg.sender && sAllowance.shadowedAmount != type(uint256).max) {
            sAllowance.shadowedAmount = _sub(
                sAllowance.shadowedAmount,
                amount,
                'FakeERC20/ALLOWANCE_UNDERFLOW'
            );
            _writeSyncedAllowance(from, msg.sender, sAllowance);
        }
        // Assume a NON MAX_UINT results in allowance update SSTORE
        _writeSyncedAllowance(from, msg.sender, sAllowance);
    }

    function _add(uint256 a, uint256 b, string memory errMsg)
        private
        pure
        returns (uint256 c)
    {
        c = a + b;
        require(c >= a, errMsg);
    }

    function _sub(uint256 a, uint256 b, string memory errMsg)
        private
        pure
        returns (uint256 c)
    {
        c = a - b;
        require(c <= a, errMsg);
    }
}