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

    constructor(IPokeMe pokeMe_, IPokeMeResolver pokeMeResolver_) {
        pokeMe = pokeMe_;
        pokeMeResolver = pokeMeResolver_;
    }

    /**
     * @notice Initializes the OlympusProOptionFactory contract
     * @param owner_ is the owner of the contract who can set the manager
     * @param bondDepository_ is the Olympus bond depository address
     */
    function initialize(
        address owner_,
        address bondDepository_)
    external
    initializer
    {
        require(owner_ != address(0), "!owner_");
        require(bondDepository_ != address(0), "!bondDepository_");

        __ReentrancyGuard_init();
        __Ownable_init();
        transferOwnership(owner_);

        bondDepository = IBondDepository(bondDepository_);
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