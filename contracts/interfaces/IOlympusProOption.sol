// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {Option} from "../structs/SOption.sol";
import {
    Option,
    OptionSettlement,
    BuyParams,
    OptionParams,
    MarketParams
} from "../structs/SOption.sol";

interface IOlympusProOption {
    function createMarket(MarketParams calldata params_) external returns(address pool, uint256 poolId);
    function buyCall(BuyParams calldata params_) external payable returns (uint256 tokenId);
    function settle(address, uint256) external;
    function exercise(uint256) external;
    function options(uint256) external view returns (Option memory);
    function isOptionExpired(uint256) external view returns (bool);
}
