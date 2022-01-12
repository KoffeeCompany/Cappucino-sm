
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {Options} from "./structs/SOption.sol";

interface IOptionPool {
    function optionsByReceiver(address) external view returns(Options memory);

    function expiryTime() external view returns (uint256);

    function timeBeforeDeadLine() external view returns (uint256);

    function settle(address, uint256) external;
}