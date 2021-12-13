// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPokeMe} from "./interfaces/IPokeMe.sol";
import {OptionPool} from "./OptionPool.sol";
import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Proxied} from "./vendor/hardhat-deploy/Proxied.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    PausableUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {
    AddressUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {
    IPokeMeResolver
} from "./IPokeMeResolver.sol";

contract OptionPoolFactory is
    Initializable,
    Proxied,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable {
    using SafeERC20 for IERC20;

    IPokeMe public immutable pokeMe;
    IPokeMeResolver public immutable pokeMeResolver;

    mapping(bytes32 => address) public getCallOptions;
    address[] public allOptions;

    event OptionPoolCreated(
        bytes32 salt,
        IERC20 indexed short,
        IERC20 indexed base,
        uint256 expiryTime,
        uint256 strike,
        uint256 timeBeforeDeadLine,
        uint256 bcv,
        uint256 initialTotalSupply
    );

    constructor(IPokeMe pokeMe_, IPokeMeResolver pokeMeResolver_) {
        pokeMe = pokeMe_;
        pokeMeResolver = pokeMeResolver_;
    }

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
        bytes32 salt = getSalt(short_, base_, expiryTime_);

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
            bcv_,
            pokeMe,
            pokeMeResolver
        );
        OptionPool(option).transferOwnership(msg.sender);
        getCallOptions[salt] = option;
        allOptions.push(option);

        base_.safeTransferFrom(msg.sender, address(this), initialTotalSupply_);
        base_.safeTransfer(option, initialTotalSupply_);
        emit OptionPoolCreated(
            salt,
            short_,
            base_,
            expiryTime_,
            strike_,
            timeBeforeDeadLine_,
            bcv_,
            initialTotalSupply_
        );
    }

    function getSalt(
        IERC20 short_,
        IERC20 base_,
        uint256 expiryTime_
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(short_, base_, expiryTime_));
    }
}
