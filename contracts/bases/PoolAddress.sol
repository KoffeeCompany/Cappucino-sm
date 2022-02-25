// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {
    Terms
} from "../structs/SPool.sol";

/// @title Provides functions for deriving a pool address from the owner, tokens
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xc02f72e8ae5e68802e6d893d58ddfb0df89a2f4c9c2f04927db1186a293736AA;

    /// @notice Returns Terms: the ordered tokens with the matched fee levels
    /// @param token0_ The first token of a pool, unsorted
    /// @param token1_ The second token of a pool, unsorted
    /// @param owner_ The owner of the pool
    function getTerms(
        address token0_,
        address token1_,
        address owner_,
        uint256 fee_,
        uint256 timeBeforeDeadline_,
        uint256 bcv_
    ) internal pure returns (Terms memory) {
        return Terms({owner: owner_, token0: token0_, token1: token1_, fee: fee_, timeBeforeDeadline: timeBeforeDeadline_, bcv: bcv_});
    }
}