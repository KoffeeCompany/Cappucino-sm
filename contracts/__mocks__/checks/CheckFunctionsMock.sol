// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {
    _checkDiffTokens,
    _checkTokenNoAddressZero,
    _checkPoolNotExist
} from "../../checks/CheckFunctions.sol";

contract OptionPoolFactoryCheckMock {
    mapping(bytes32 => address) public getCallOptions;

    function checkDiffTokensMock(address token1_, address token2_) external pure {
        _checkDiffTokens(token1_, token2_);
    }

    function checkTokenNoAddressZero(address token_) external pure {
        _checkTokenNoAddressZero(token_);
    }

    function checkPoolNotExist(
        address optionPool_,
        address token1_,
        address token2_,
        uint256 marketId_,
        uint256 expiryTime_
    ) external pure {
        _checkPoolNotExist(optionPool_, token1_, token2_, marketId_, expiryTime_);
    }
}
