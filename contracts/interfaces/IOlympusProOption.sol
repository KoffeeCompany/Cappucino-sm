// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

interface IOlympusProOption {
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

    function settle(address, uint256) external;
    function exercise(uint256) external;
}