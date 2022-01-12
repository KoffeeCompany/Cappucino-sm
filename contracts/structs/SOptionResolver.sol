
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

struct OptionCanSettle {
    address pool;
    address receiver;
    uint256 id;
}