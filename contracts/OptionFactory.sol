// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OptionPool} from "./OptionPool.sol";

contract OptionPoolFactory {

using SafeERC20 for IERC20;

    mapping(bytes32 => address) public getCallOptions;
    address[] public allOptions;

    event OptionCreated(
        IERC20 indexed short,
        IERC20 indexed base,
        uint256 expiryTime,
        uint256 strike,
        uint256 timeBeforeDeadLine,
        uint256 bcv,
        uint256 initialTotalSupply
    );

    function createCallOption(
        IERC20 short_,
        IERC20 base_,
        uint256 expiryTime_,
        uint256 strike_,
        uint256 timeBeforeDeadLine_,
        uint256 bcv_,
        uint256 initialTotalSupply_
    ) external returns (address option) {
        require(
            short_ != base_,
            "Cappucino::OptionFactory:: IDENTICAL_ADDRESSES"
        );
        // (address token0, address token1) = tokenA < tokenB
        //     ? (tokenA, tokenB)
        //     : (tokenB, tokenA);
        bytes32 salt = keccak256(abi.encode(short_, base_, expiryTime_));

        require(
            address(short_) != address(0),
            "Cappucino::OptionFactory:: short token ZERO_ADDRESS"
        );
        require(
            address(base_) != address(0),
            "Cappucino::OptionFactory:: base token ZERO_ADDRESS"
        );
        require(
            getCallOptions[salt] == address(0),
            "Cappucino::OptionFactory:: PAIR_EXISTS"
        ); // single check is sufficient
        bytes memory bytecode = type(OptionPool).creationCode;
        assembly {
            option := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        OptionPool(option).initialize(
            short_,
            base_,
            expiryTime_,
            strike_,
            timeBeforeDeadLine_,
            bcv_
        );
        getCallOptions[salt] = option;
        allOptions.push(option);

        base_.safeTransferFrom(msg.sender, address(this), initialTotalSupply_);
        base_.safeTransfer(option, initialTotalSupply_);
        emit OptionCreated(
            short_,
            base_,
            expiryTime_,
            strike_,
            timeBeforeDeadLine_,
            bcv_,
            initialTotalSupply_
        );
    }
}
