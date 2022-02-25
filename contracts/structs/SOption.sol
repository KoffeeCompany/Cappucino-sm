// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

struct Options {
    uint256 nextID;
    Option[] opts;
}

// details about the Olympus pro option
struct Option {
    // the pool id
    uint256 poolId;
    // the option notional
    uint256 notional;
    // the option strike
    uint256 strike;
    // the address that is approved for spending this token
    address operator;
    // the fee
    uint256 fee;
    // how many tokens user will get
    uint256 tokensWillReceived;
    uint256 deadline;
    uint256 createTime;
    bytes32 pokeMe;
    bool settled;
}

struct MarketParams {
    uint256 capacity; // capacity remaining    
    uint256 maxPayout; // max tokens in/out
    address treasury;
    address owner;
    address token0;
    address token1;
    uint256 fee;
    uint256 timeBeforeDeadline;
    uint256 bcv;
}


struct OptionSettlement {
    address operator;
    uint256 tokenId;
}

struct BuyParams {
    uint256 poolId;
    uint256 notional;
    uint256 strike;
    uint256 deadline;
    address recipient;
}

struct OptionParams {
    uint256 poolId;
    address recipient;
    address asset;
    address underlying;
    uint256 notional;
    uint256 strike;
    uint256 deadline;
    uint256 fee;
    uint256 tokensWillReceived;
    uint256 tokenId;
}
