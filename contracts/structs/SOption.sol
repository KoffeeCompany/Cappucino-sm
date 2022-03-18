// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

struct Options {
    uint256 nextID;
    Option[] opts;
}

struct Option {
    uint256 notional;
    uint256 previewSettleFee;
    address receiver;
    uint256 price;
    uint256 startTime;
    bytes32 pokeMe;
    bool settled;
}
