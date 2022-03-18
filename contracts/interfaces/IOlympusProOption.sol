// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {Option} from "../structs/SOption.sol";

interface IOlympusProOption {

    function settle(address, uint256) external;

    function exercise(uint256) external;

    function options(uint256) external view returns (Option memory);

    function isOptionExpired(uint256) external view returns (bool);
}
