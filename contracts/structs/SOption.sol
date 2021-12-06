// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

struct Options {
    uint256 nextID;
    Option[] opts;
}

struct Option {
    uint256 notional;
    address receiver;
    uint256 price;
}
