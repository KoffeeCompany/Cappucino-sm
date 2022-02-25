// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import { IOlympusProPool } from "./interfaces/IOlympusProPool.sol";
import { Parameters, PoolCreationParams, Terms } from "./structs/SPool.sol";
import "./OlympusProPool.sol";
import "./bases/PoolAddress.sol";
import {OlympusProManager} from "./OlympusProManager.sol";

abstract contract OlympusProPoolManager is OlympusProManager
{
    /// @dev IDs of pools
    mapping(address => uint256) private _poolIds;
    mapping(uint256 => address) internal _pools;
    /// @dev pool IDs to Terms
    mapping(uint256 => Terms) internal _poolIdToTerms;
    /// @dev The ID of the next pool that is used for the first time. Skips 0
    uint256 private _nextPoolId = 1;

    mapping(address => mapping(address => mapping(address => address))) public getPool;
    Parameters public parameters;

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool
    /// @param token1 The second token of the pool
    /// @param owner The pool owner
    /// @param treasury The treasury address
    /// @param pool The address of the created pool
    event PoolCreated(
        address token0,
        address token1,
        address owner,
        address treasury,
        address pool
    );

    function createPool(PoolCreationParams memory params_) 
    public returns (address pool, uint256 poolId) {
        require(params_.token0 != address(0), "!token0_");
        require(params_.token1 != address(0), "!token1_");
        require(params_.token0 != params_.token1);
        require(params_.owner != address(0), "!owner_");
        require(params_.treasury != address(0), "!treasury_");
        require(params_.capacity != 0, "!capacity_");
        require(params_.maxPayout != 0, "!maxPayout_");
        require(params_.timeBeforeDeadline != 0, "!timeBeforeDeadline_");
        require(params_.bcv != 0, "!bcv_");
        require(params_.fee != 0, "!fee_");
        require(getPool[params_.token0][params_.token1][params_.owner] == address(0));

        (pool, poolId) = _deploy(address(this), params_.token0, params_.token1, params_.owner, params_.treasury, params_.capacity, params_.maxPayout, params_.timeBeforeDeadline, params_.bcv, params_.fee);
        getPool[params_.token0][params_.token1][params_.owner] = pool;
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[params_.token1][params_.token0][params_.owner] = pool;
        emit PoolCreated(params_.token0, params_.token1, params_.owner, params_.treasury, pool);
    }

    /// @dev Deploys a pool with the given parameters by transiently setting the parameters storage slot and then
    /// clearing it after deploying the pool.
    /// @param factory_ The contract address of the OlympusPro factory
    /// @param token0_ The first token of the pool
    /// @param token1_ The second token of the pool
    /// @param owner_ The pool owner 
    /// @param treasury_ The treasury address
    /// @param capacity_ is the capacity of the pool
    /// @param maxPayout_ is the max payout of the pool
    /// @param timeBeforeDeadline_ is the option limit time
    /// @param bcv_ is the bcv factor
    /// @param fee_ is the fee ratio
    function _deploy(
        address factory_,
        address token0_,
        address token1_,
        address owner_,
        address treasury_,
        uint256 capacity_,
        uint256 maxPayout_,
        uint256 timeBeforeDeadline_,
        uint256 bcv_,
        uint256 fee_
    ) internal returns (address poolAddress, uint256 poolId) {
        parameters = Parameters({factory: factory_, token0: token0_, token1: token1_, owner: owner_});
        OlympusProPool pool = new OlympusProPool{salt: keccak256(abi.encode(token0_, token1_, owner_))}(factory_, token0_, token1_, owner_);
        pool.initialize(treasury_, capacity_, maxPayout_, timeBeforeDeadline_, bcv_, fee_);

        // cache the pool terms  
        Terms memory poolTerms = PoolAddress.getTerms(token0_, token1_, owner_, fee_, timeBeforeDeadline_, bcv_);

        poolAddress = address(pool);
        poolId = _cachePoolTerms(poolAddress, poolTerms);
        delete parameters;
    }

    /// @dev Caches a pool key
    function _cachePoolTerms(address pool_, Terms memory poolKey_) private returns (uint256 poolId) {
        poolId = _poolIds[pool_];
        if (poolId == 0) {
            _poolIds[pool_] = (poolId = _nextPoolId++);
            _poolIdToTerms[poolId] = poolKey_;
            _pools[poolId] = pool_;
        }
    }

}