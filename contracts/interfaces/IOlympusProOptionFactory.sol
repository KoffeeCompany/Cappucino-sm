// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {IPokeMe} from "../interfaces/IPokeMe.sol";
import {
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IOlympusProOptionFactory {
    function pokeMe() external view returns (IPokeMe);
    function createMarket(
        uint256 capacity_,
        uint256 maxPayout_,
        address treasury_,
        address token0_,
        address token1_,
        uint256 bcv_) 
    external returns(uint256);
    function buyCall(
        uint256 marketId_,
        uint256 expiryTime_,
        uint256 strike_,
        uint256 notional_
    ) external returns (uint256);
}