
// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

struct OptionCanSettle {
    address pool;
    address receiver;
    uint256 id;
}