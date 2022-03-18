// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

function _getSalt(
    IERC20 short_,
    IERC20 base_,
    uint256 marketId_,
    uint256 expiryTime_
) pure returns (bytes32) {
    return keccak256(abi.encode(marketId_, short_, base_, expiryTime_));
}