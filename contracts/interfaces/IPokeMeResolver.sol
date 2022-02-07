// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import {OptionCanSettle} from "../structs/SOptionResolver.sol";

interface IPokeMeResolver {
    function checker(
        OptionCanSettle memory optionCanSettle
    ) external view returns (bool, bytes memory);
}
