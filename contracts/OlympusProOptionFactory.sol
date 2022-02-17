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
    address public immutable bondDepository;
    address public immutable olympusPool;

    // !!!!!!!!!!!!!!!! DONT CHANGE ORDER !!!!!!!!!!!!!!!!!
    mapping(bytes32 => address) public getCallOptions;
    address[] public allOptions;
    // ADD new mutable properties here.

    // !!!!!!!!!!! EVENTS !!!!!!!!!!!!!!

    event OlympusProOptionCreated(
        bytes32 salt,
        IERC20 indexed short,
        IERC20 indexed base,
        uing256 marketId,
        uint256 expiryTime,
        uint256 strike,
        uint256 timeBeforeDeadLine,
        uint256 bcv
    );

    constructor(IPokeMe pokeMe_, 
        IPokeMeResolver pokeMeResolver_, 
        address bondDepository_,
        address olympusPool_
    ) {
        pokeMe = pokeMe_;
        pokeMeResolver = pokeMeResolver_;
        bondDepository = bondDepository_;
        olympusPool = olympusPool_;
    }

    function createCallOption(
        IERC20 short_,
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
            address short = address(short_);
            address base = address(base_);

            salt = getSalt(marketId, short_, base_, expiryTime_);

            _checkDiffTokens(short, base);
            _checkTokenNoAddressZero(short);
            _checkTokenNoAddressZero(base);
            _checkPoolNotExist(getCallOptions[salt], short, base, marketId_, expiryTime_);
        }

        // |||||||||||| EFFECT  |||||||||||||||

        bytes memory bytecode = type(OlympusProOption).creationCode;

        bytes memory encodePacked = abi.encodePacked(bytecode, abi.encode(address(base_), address(short_), olympusPool, bondDepository, pokeMe, pokeMeResolver));

        assembly {
            option := create2(0, add(encodePacked, 32), mload(bytecode), salt)
        }
        getCallOptions[salt] = option;
        allOptions.push(option);

        // |||||||||||| INTERACTION |||||||||||||

        OlympusProOption(option).initialize(
            msg.sender,
            marketId_,
            timeBeforeDeadLine_,
            bcv_
        );

        emit OlympusProOptionCreated(
            salt,
            short_,
            base_,
            marketId_,
            expiryTime_,
            strike_,
            timeBeforeDeadLine_,
            bcv_
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
        require(bondDepository != address(0), "!bondDepository");

        IBondDepository bond = IBondDepository(bondDepository);
        liveMarkets_ = bond.liveMarkets();
    }
}