// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

struct Parameters {
    address factory;
    address quote;
    address base;
    address owner;
}

struct PoolCreationParams {
    address quote;
    address base;
    address owner;
    address treasury;
    uint256 capacity;
    uint256 maxPayout;
    uint256 timeBeforeDeadline;
    uint256 bcv;
    uint256 fee;
}

struct Terms {
    address owner;
    address quote;
    address base;
    uint256 fee;
    uint256 timeBeforeDeadline;
    uint256 bcv;
}