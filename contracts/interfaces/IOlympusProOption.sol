// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

interface IOlympusProOption {
    struct MintParams {
        address recipient;
        uint256 notional;
        uint256 strike;
        uint256 deadline;
    }
}