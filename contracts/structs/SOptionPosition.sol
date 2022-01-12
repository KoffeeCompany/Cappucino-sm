// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

// Non Fungible Token Position
struct OptionPosition {
    uint256 notional;
    address receiver;
    uint256 price;
    uint256 startTime;
    bytes32 pokeMe;
    bool settled;
}