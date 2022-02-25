// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

struct Parameters {
    address factory;
    address token0;
    address token1;
    address owner;
}

struct PoolCreationParams {
    address token0;
    address token1;
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
    address token0;
    address token1;
    uint256 fee;
    uint256 timeBeforeDeadline;
    uint256 bcv;
}