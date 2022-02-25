// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

function _getSalt(
    address short_,
    address base_,
    address owner_
) pure returns (bytes32) {
    return keccak256(abi.encodePacked(short_, base_, owner_));
}