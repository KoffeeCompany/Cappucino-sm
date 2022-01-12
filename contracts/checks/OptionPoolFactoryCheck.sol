// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

// 0x01 : address1 == address2
// 0x02 : address == address(0)
// 0x03 ; pool exist

error InvalidTokens(address short, address base, bytes1 code);
error InvalidTokenZero(address token, bytes1 code);
error OptionPoolExist(address short, address base, uint256 expiry, bytes1 code);

function _checkDiffTokens(address token0_, address token1_) pure {
    if (token0_ == token1_) revert InvalidTokens(token0_, token1_, 0x01);
}

function _checkTokenNoAddressZero(address token_) pure {
    if (token_ == address(0)) revert InvalidTokenZero(token_, 0x02);
}

function _checkPoolNotExist(
    address callOptionPool_,
    address short_,
    address base_,
    uint256 expiryTime_
) pure {
    if (callOptionPool_ != address(0))
        revert OptionPoolExist(short_, base_, expiryTime_, 0x03);
}
