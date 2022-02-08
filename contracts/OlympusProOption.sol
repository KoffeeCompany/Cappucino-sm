// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import { IOlympusProOption } from "./interfaces/IOlympusProOption.sol";
import { OlympusProOptionManager } from "./OlympusProOptionManager.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {BlockTimestamp} from "./bases/BlockTimestamp.sol";
import {ExpiryValidation} from "./bases/ExpiryValidation.sol";
import {IBondDepository} from "./interfaces/Olympus/IBondDepository.sol";
import "./vendor/DSMath.sol";

contract OlympusProOption is IOlympusProOption, BlockTimestamp, ExpiryValidation, OlympusProOptionManager
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public immutable asset;
    address public immutable underlying;
    address public immutable olympusPool;
    address public immutable bondDepository;

    uint256 private _marketId;
    uint256 private _bcv;

    // details about the Olympus pro option
    struct Option {
        // the option notional
        uint256 notional;
        // the option strike
        uint256 strike;
        // the address that is approved for spending this token
        address operator;
        // the fees
        uint256 feeExercise;
        uint256 feeSettle;
        // how many tokens user will get
        uint128 tokensWillReceived;
        
        bytes32 pokeMe;
    }


    /// @dev The market ID option data by user address
    mapping(uint256 => mapping(address => Option)) private _options;

    /// @dev The ID of the next token that will be minted. Skips 0
    uint176 private _nextId = 1;

    /**
     * @notice Initializes the contract with immutable variables
     * @param baseToken_ is the asset used for collateral
     * @param quoteToken_ is the asset used for premiums and result asset
     * @param factory_ is the option factory contract address
     * @param registry_ is the option registry contract address 
     * @param olympusPool_ is the Olympus pool address
     * @param bondDepository_ is the bonddepository address
     */
    constructor(
        address baseToken_,
        address quoteToken_,
        address factory_,
        address registry_,
        address olympusPool_,
        address bondDepository_
    ) {
        require(baseToken_ != address(0), "!baseToken_");
        require(quoteToken_ != address(0), "!quoteToken_");
        require(factory_ != address(0), "!factory_");
        require(registry_ != address(0), "!registry_");
        require(olympusPool_ != address(0), "!olympusPool_");
        require(bondDepository_ != address(0), "!bondDepository_");

        asset = quoteToken_;
        underlying = baseToken_;
        olympusPool = olympusPool_;
        bondDepository = bondDepository_;
    }

    /**
     * @notice Initializes the contract with storage variables.
     * @param owner_ is the owner of the contract who can set the manager
     * @param marketId_ is the ID of the market
     * @param timeBeforeDeadLine_ is the option limit time
     * @param bcv_ is the bcv factor
     */
    function initialize(
        address owner_,   
        uint256 marketId_,  
        uint256 timeBeforeDeadLine_,
        uint256 bcv_
    ) external initializer {
        require(owner_ != address(0), "!owner_");
        require(timeBeforeDeadLine_ != 0, "!timeBeforeDeadLine_");
        require(bcv_ != 0, "!bcv_");

        __ReentrancyGuard_init();
        __Ownable_init();
        transferOwnership(owner_);
        __ERC721_init("Olympus Option NFT-V1", "OHM-OPT");

        // hardcode the initial exercise fee and settle fee
        instantExerciseFee = _wdiv(5, 1000);
        instantSettleFee = 0;

        _marketId = marketId_;
        _bcv = bcv_;

        timeBeforeDeadline = timeBeforeDeadLine_;
    }

    /**
     * @notice Initializes the contract with storage variables.
     * @param params mint parameter composed by : 
     * recipient is the buyer of the contract who pay the premium
     * notional is the amount of quote token to spend
     * deadline is the option expiry time
     * strike is the price at which to exercise option
     */
    function mint(MintParams calldata params)   
        external
        payable
        nonReentrant
        checkExpiry(params.deadline, timeBeforeDeadline)
        returns (
            uint256 tokenId
        ) {
        require(params.recipient != address(0), "!recipient");
        require(params.notional != 0, "!notional");
        require(params.strike != 0, "!strike");

        uint256 olympusBalance = olympusAssetBalance();        
        uint256 debt = _wmul(params.notional, params.strike);
        uint256 fee = maxFee(debt);

        require(debt + fee <= olympusBalance, "debt + fee > olympusBalance.");
        // lock the return amount from olympus pool
        IERC20(underlying).safeTransferFrom(olympusPool, address(this), _add(debt,fee));

        // lock the premium amount from the user
        uint256 prime = prime(params.strike);
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), prime);
        _safeMint(params.recipient, (tokenId = _nextId++));
    }

    /**
     * @notice Returns the asset balance on the olympus pool.
     */
    function olympusAssetBalance() public view returns (uint256) {
        return IERC20(underlying).balanceOf(olympusPool);
    }

    /**
     * @notice Returns the maximum fee between the settlement and the exercise.
     */
    function maxFee(uint256 debt) public view returns (uint256 fee) {      
        uint256 feeExercise = 0;
        uint256 feeSettle = 0;
        if(instantExerciseFee != 0){
            feeExercise = _wmul(debt, instantExerciseFee);
        }        
        require(feeExercise >= 0, "exercise fee detected is negative.");

        if(instantSettleFee != 0){
            feeSettle = _wmul(debt, instantSettleFee);
        }        
        require(feeSettle >= 0, "settle fee detected is negative.");
        fee = feeExercise;
        if(feeSettle > feeExercise)
        {
            fee = feeSettle;
        }
    }

    /**
     * @notice Returns the prime by market id.
     */
    function prime(uint256 strike) public view returns (uint256 prime) {      
        // TODO : what about the strike ???
        IBondDepository bond = IBondDepository(bondDepository);
        uint256 debtRatio = bond.debtRatio(_marketId);
        prime = _wmul(debtRatio, _bcv);
    }
}