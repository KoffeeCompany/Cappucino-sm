// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

struct OptionCanSettle {
    address pool;
    address receiver;
    uint256 id;
}