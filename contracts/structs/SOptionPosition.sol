// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

// Non Fungible Token Position
struct OptionPosition {
    uint256 notional;
    address receiver;
    uint256 price;
    uint256 startTime;
    bytes32 pokeMe;
    bool settled;
}