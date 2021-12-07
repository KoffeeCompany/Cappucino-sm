// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {CALL, PUT} from "../constants/COption.sol";
import {OptionPoolMock} from "./OptionPoolMock.sol";

contract OptionPoolFactoryMock {
    // !!!!!!!!!!!! EVENTS !!!!!!!!!!!!!!!!

    event LogOptionPoolCreation(
        bytes32 hash,
        address pool,
        address base,
        address short,
        string optionType,
        uint256 liquidity,
        uint256 bcv,
        uint256 strike,
        uint256 maturity
    );

    // !!!!!!!!!!!! EVENTS !!!!!!!!!!!!!!!!

    mapping(bytes32 => address) public optionPools;

    function createOptionPool(
        address base_,
        address short_,
        string memory optionType_,
        uint256 liquidity_,
        uint256 bcv_,
        uint256 strike_,
        uint256 maturity_
    ) external {
        OptionPoolMock optionPool = new OptionPoolMock(
            base_,
            short_,
            optionType_,
            liquidity_,
            bcv_,
            strike_,
            maturity_
        );
        bytes32 hash = keccak256(
            abi.encode(
                address(optionPool),
                base_,
                short_,
                optionType_,
                liquidity_,
                bcv_,
                strike_,
                maturity_
            )
        );

        optionPools[hash] = address(optionPool);

        optionPool.transferOwnership(msg.sender);

        emit LogOptionPoolCreation(
            hash,
            address(optionPool),
            base_,
            short_,
            optionType_,
            liquidity_,
            bcv_,
            strike_,
            maturity_
        );
    }
}
