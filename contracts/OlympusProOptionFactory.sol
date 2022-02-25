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
import { IOlympusProOptionFactory } from "./interfaces/IOlympusProOptionFactory.sol";
import {IPokeMe} from "./interfaces/IPokeMe.sol";
import {IPokeMeResolver} from "./interfaces/IPokeMeResolver.sol";
import {IOlympusProOption} from "./interfaces/IOlympusProOption.sol";
import {OlympusProOption} from "./OlympusProOption.sol";
import {
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    MarketParams
} from "./structs/SOption.sol";
import {
    BuyParams,
    MarketParams
} from "./structs/SOption.sol";
import {
    _getSalt
} from "./functions/FOlympusProOptionFactory.sol";
import {
    _wdiv
} from "./vendor/DSMath.sol";

contract OlympusProOptionFactory is 
    IOlympusProOptionFactory,
    Initializable,
    Proxied,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable {
        
    IPokeMe public immutable pokeMe;
    IPokeMeResolver public immutable pokeMeResolver;

    IOlympusProOption public immutable optionManager;

    mapping(bytes32 => uint256) public markets;

    uint256 public timeBeforeDeadline;
    uint256 public fee;

    // !!!!!!!!!!! EVENTS !!!!!!!!!!!!!!

    event OlympusProOptionCreated(
        uint256 marketId,
        uint256 expiryTime,
        uint256 strike,
        uint256 notional
    );

    constructor(IPokeMe pokeMe_, 
        IPokeMeResolver pokeMeResolver_
    ) {
        pokeMe = pokeMe_;
        pokeMeResolver = pokeMeResolver_;
        optionManager = new OlympusProOption(address(this), pokeMe, pokeMeResolver);

        fee = _wdiv(5, 10**3);
        timeBeforeDeadline = 3600 * 24; // 1 day
    }

    /**
     * @notice Initializes the contract
     */
    function initialize() external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        transferOwnership(msg.sender);
    }

    function createMarket(
        uint256 capacity_,
        uint256 maxPayout_,
        address treasury_,
        address token0_,
        address token1_,
        uint256 bcv_) 
    external nonReentrant returns(uint256) {
        require(capacity_ != 0, "!capacity");
        require(maxPayout_ != 0, "!maxPayout");
        require(treasury_ != address(0), "!treasury");
        require(token0_ != address(0), "!token0");
        require(token1_ != address(0), "!token1");
        require(token0_ != token1_, "token0 == token1");
        require(token1_ != address(0), "!token1");
        require(bcv_ != 0, "!bcv");

        bytes32 salt = _getSalt(token0_, token1_, msg.sender);
        require(markets[salt] == 0, "market already exists");

        address pool;
        uint256 poolId;
        (pool, poolId) = optionManager.createMarket(
            MarketParams({
                capacity : capacity_,
                maxPayout : maxPayout_,
                treasury : treasury_,
                owner : msg.sender,
                token0 : token0_,
                token1 : token1_,
                fee: fee,
                timeBeforeDeadline : timeBeforeDeadline,
                bcv : bcv_
            }));
        markets[salt] = poolId;
        
        return poolId;
    }

    function buyCall(
        uint256 marketId_,
        uint256 expiryTime_,
        uint256 strike_,
        uint256 notional_
    ) external returns (uint256 optionId) {

        require(marketId_ != 0, "!marketId");
        require(expiryTime_ != 0, "!expiryTime");
        require(strike_ != 0, "!strike");
        require(notional_ != 0, "!notional");

        optionId = optionManager.buyCall(
            BuyParams({
                poolId : marketId_,
                notional : notional_,
                strike : strike_,
                recipient : msg.sender,
                deadline : expiryTime_
            }));

        emit OlympusProOptionCreated(
            marketId_,
            expiryTime_,
            strike_,
            notional_
        );
    }
}