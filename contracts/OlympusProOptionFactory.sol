// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Proxied} from "./vendor/hardhat-deploy/Proxied.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IBondDepository } from "./interfaces/Olympus/IBondDepository.sol";
import { IOlympusProOptionFactory } from "./interfaces/IOlympusProOptionFactory.sol";
import {IPokeMe} from "./interfaces/IPokeMe.sol";
import {IPokeMeResolver} from "./interfaces/IPokeMeResolver.sol";

contract OlympusProOptionFactory is 
    IOlympusProOptionFactory,
    Initializable,
    Proxied,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable {
        
    IPokeMe public immutable pokeMe;
    IPokeMeResolver public immutable pokeMeResolver;
    IBondDepository private bondDepository;

    // !!!!!!!!!!!!!!!! DONT CHANGE ORDER !!!!!!!!!!!!!!!!!
    mapping(bytes32 => address) public getCallOptions;
    address[] public allOptions;
    // ADD new mutable properties here.

    // !!!!!!!!!!! EVENTS !!!!!!!!!!!!!!

    constructor(IPokeMe pokeMe_, 
        IPokeMeResolver pokeMeResolver_, 
        IBondDepository bondDepository_
    ) {
        pokeMe = pokeMe_;
        pokeMeResolver = pokeMeResolver_;
        bondDepository = bondDepository_;
    }

    function createCallOption(
        IERC20 base_,
        uint256 marketId_,
        uint256 timeBeforeDeadLine_,
        uint256 expiryTime_,
        uint256 strike_,
        uint256 bcv_
    ) external returns (address option) {
        // |||||||||||||  CHECK  |||||||||||||||
        bytes32 salt;
        {
            address base = address(base_);

            salt = getSalt(base_, marketId_, expiryTime_);

            _checkTokenNoAddressZero(base);
            _checkPoolNotExist(getCallOptions[salt], base, expiryTime_);
        }

        // |||||||||||| EFFECT  |||||||||||||||

        bytes memory bytecode = type(OlympusProOption).creationCode;

        assembly {
            option := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        getCallOptions[salt] = option;
        allOptions.push(option);

        // |||||||||||| INTERACTION |||||||||||||

        OlympusProOption(option).initialize(
            short_,
            base_,
            weth_,
            expiryTime_,
            strike_,
            timeBeforeDeadLine_,
            bcv_,
            pokeMe,
            pokeMeResolver
        );
        OptionPool(option).transferOwnership(msg.sender);

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
        return _getSalt(short_, base_, expiryTime_);
    }

    /**
     * @notice get all live markets
     */
    function liveMarkets()
    external
    returns(uint256[] memory liveMarkets_)
    {
        require(address(bondDepository) != address(0), "!bondDepository");

        liveMarkets_ = bondDepository.liveMarkets();
    }
}