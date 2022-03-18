// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

struct Options {
    uint256 nextID;
    Option[] opts;
}

// details about the Olympus pro option
struct Option {
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

struct OptionSettlement {
    address operator;
    uint256 tokenId;
}

struct BuyParams {
    uint256 notional;
    uint256 strike;
    uint256 deadline;
}

struct OptionParams {
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
