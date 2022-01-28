# Foundry playground

## FakeERC20

Replaces ERC20 token code with a fake implementation that allows for balance overrides whilst maintaining existing balances.

No more messing about with pretending to be token whales and praying they don't move funds.
No more pretending to be a rich contract and finding out its used somewhere down the stack.

⚠️ Warning: This increases the gas cost of all transactions using faked tokens.

```solidity
    // Fake out WETH
    FakeERC20 fakeToken = fakeOutERC20(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
    fakeToken._setBalance(address(this), 1e18);
    IERC20Token(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).balanceOf(address(this)); // => 1e18
```

To get an idea of what's happening under the hood, take a look at the call trace.

```
[PASS] testFakeERC20() (gas: 93054)
Traces:
  [93054] ERC20TokenFakerTest::testFakeERC20()
    ├─ [2534] 0xc02a…6cc2::balanceOf(0xb4c79dab8f259c7aee6e5b2aa729821864227e84)
    │   └─ ← 0
    ├─ [0] VM::etch(0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc3, ORIGINAL ERC20 CODE)
    │   └─ ← ()
    ├─ [0] VM::etch(0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2, FAKED ERC20 CODE)
    │   └─ ← ()
    ├─ [51986] 0xc02a…6cc2::_setBalance(0xb4c79dab8f259c7aee6e5b2aa729821864227e84, 10000000000000000000)
    │   ├─ [534] 0xc02a…6cc3::balanceOf(0xb4c79dab8f259c7aee6e5b2aa729821864227e84)
    │   │   └─ ← 0
    │   └─ ← 10000000000000000000
    ├─ [2836] 0xc02a…6cc2::balanceOf(0xb4c79dab8f259c7aee6e5b2aa729821864227e84)
    │   ├─ [534] 0xc02a…6cc3::balanceOf(0xb4c79dab8f259c7aee6e5b2aa729821864227e84)
    │   │   └─ ← 0
    │   └─ ← 10000000000000000000
```
