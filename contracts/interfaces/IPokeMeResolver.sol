// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import {OptionCanSettle} from "../structs/SOptionResolver.sol";

interface IPokeMeResolver {
    struct SettleParams {
        address optionAddress;
        address operator;
        uint256 tokenId;
    }

    function checker(
        SettleParams memory params
    ) external view returns (bool, bytes memory);
}
