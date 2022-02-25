// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {IOlympusProOption} from "./interfaces/IOlympusProOption.sol";
import {OlympusProPoolManager} from "./OlympusProPoolManager.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {BlockTimestamp} from "./bases/BlockTimestamp.sol";
import {IBondDepository} from "./interfaces/Olympus/IBondDepository.sol";
import {IPokeMe} from "./interfaces/IPokeMe.sol";
import {IPokeMeResolver} from "./interfaces/IPokeMeResolver.sol";
import { IOlympusProOptionFactory } from "./interfaces/IOlympusProOptionFactory.sol";
import { OlympusProPool } from "./OlympusProPool.sol";
import {
    _add,
    _wmul,
    _wdiv,
    _smul,
    _sdiv,
    _omul,
    _odiv
} from "./vendor/DSMath.sol";
import {
    Option,
    OptionSettlement,
    BuyParams,
    OptionParams,
    MarketParams
} from "./structs/SOption.sol";
import {
    Terms,
    PoolCreationParams
} from "./structs/SPool.sol";
import "./bases/PoolAddress.sol";

contract OlympusProOption is
    IOlympusProOption,
    BlockTimestamp,
    ERC721Upgradeable,
    OlympusProPoolManager
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public immutable factory;
    IPokeMe public pokeMe;
    IPokeMeResolver public pokeMeResolver;

    /// @dev options by tokenId
    mapping(uint256 => Option) private _options;

    /// @dev tokenId to poolId
    mapping(uint256 => uint256) private _tokenIdToPoolId;

    /// @dev The ID of the next token that will be minted. Skips 0
    uint176 private _nextId = 1;

    /**
     * @notice Initializes the contract with immutable variables
     * @param factory_ is the factory address
     * @param pokeMe_ is the pokeMe instance
     * @param pokeMeResolver_ is the pokeMe resolver
     */
    constructor(
        address factory_,
        IPokeMe pokeMe_,
        IPokeMeResolver pokeMeResolver_
    ) {
        require(factory_ != address(0), "!factory_");
        require(address(pokeMe_) != address(0), "!pokeMe_");
        require(address(pokeMeResolver_) != address(0), "!pokeMeResolver_");

        pokeMe = pokeMe_;
        pokeMeResolver = pokeMeResolver_;
        factory = factory_;
    }

    /**
     * @notice Initializes the contract
     */
    function initialize() external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        transferOwnership(msg.sender);
        __ERC721_init("Olympus Option NFT-V1", "OHM-OPT");
    }

    function createMarket(MarketParams calldata params_)
    external nonReentrant returns (address pool, uint256 poolId)
    {  
        require(params_.capacity != 0, "!capacity");
        require(params_.maxPayout != 0, "!maxPayout");
        require(params_.owner != address(0), "!owner");
        require(params_.treasury != address(0), "!treasury");
        require(params_.token0 != address(0), "!token0");
        require(params_.token1 != address(0), "!token1");
        require(params_.timeBeforeDeadline != 0, "!timeBeforeDeadline");
        require(params_.bcv != 0, "!bcv");
        require(params_.fee != 0, "!fee");

        require(getPool[params_.token0][params_.token1][params_.owner] == address(0), "market already exists");

        (pool, poolId) = createPool(
            PoolCreationParams({
                token0: params_.token0,
                token1: params_.token1,
                owner: params_.owner,
                treasury: params_.treasury,
                capacity: params_.capacity,
                maxPayout: params_.maxPayout,
                timeBeforeDeadline: params_.timeBeforeDeadline,
                bcv: params_.bcv,
                fee: params_.fee
            })
        );
    }

    /**
     * @notice Buy the option.
     * @param params_ mint parameter composed by :
     * recipient is the buyer of the contract who pay the premium
     * notional is the amount of quote token to spend
     * deadline is the option expiry time
     * strike is the price at which to exercise option
     */
    function buyCall(BuyParams calldata params_)
        external
        payable
        nonReentrant
        returns (uint256 tokenId)
    {
        require(params_.notional != 0, "OlympusProOption::buy: !notional");
        require(params_.strike != 0, "OlympusProOption::buy: !strike");
        require(params_.poolId != 0, "Invalid pool ID");
        require(params_.deadline != 0, "!deadline");
        require(params_.recipient != address(0), "!recipient");
           
        Terms memory poolTerms = _poolIdToTerms[params_.poolId];
        require(poolTerms.token0 != address(0), "!token0");
        require(poolTerms.token1 != address(0), "!token1");
        require(_blockTimestamp() + poolTerms.timeBeforeDeadline <= params_.deadline, "Transaction too old");
        address poolAddress = _pools[params_.poolId];
        require(poolAddress != address(0), "!poolAddress");
        OlympusProPool pool = OlympusProPool(poolAddress);

        uint256 treasuryBalance = pool.balance1();
        uint256 debt = _wmul(params_.notional, params_.strike);
        uint256 fee = _maxFee(pool.instantFee(), debt);

        require(debt + fee <= treasuryBalance, "debt + fee > treasuryBalance.");
        address underlying = pool.token1();
        // lock the return amount from treasury pool
        pool.lockTreasuryAmount1(address(this), debt, fee);

        // lock the premium amount from the user
        // TODO check if prime has notional precision.
        // Should be set that way during initialization?
        uint256 prime = prime(pool.debtRatio(), poolTerms.bcv);
        pool.getPrimeAmount1(params_.recipient, address(this), prime, params_.notional);
        _safeMint(params_.recipient, (tokenId = _nextId++));

        OptionParams memory opar = OptionParams({
            poolId: params_.poolId,
            notional: params_.notional,
            recipient: params_.recipient,
            strike: params_.strike,
            fee: fee,
            tokensWillReceived: debt,
            asset: poolTerms.token0,
            underlying: poolTerms.token1,
            tokenId: tokenId,
            deadline: params_.deadline
        });
        _options[tokenId] = _createOption(opar);
        _tokenIdToPoolId[tokenId] = params_.poolId;
    }

    function _createOption(OptionParams memory params_)
        private
        returns (Option memory)
    {
        return
            Option({
                poolId: params_.poolId,
                notional: params_.notional,
                operator: params_.recipient,
                strike: params_.strike,
                deadline: params_.deadline,
                createTime: _blockTimestamp(),
                fee: params_.fee,
                tokensWillReceived: params_.tokensWillReceived,
                pokeMe: pokeMe.createTaskNoPrepayment(
                    address(this),
                    this.settle.selector,
                    address(pokeMeResolver),
                    abi.encodeWithSelector(
                        IPokeMeResolver.checker.selector,
                        OptionSettlement({
                            operator: params_.recipient,
                            tokenId: params_.tokenId
                        })
                    ),
                    params_.underlying
                ),
                settled: false
            });
    }

    function _deleteAndBurn(uint256 tokenId_)
        private
    {
        delete _options[tokenId_];
        _burn(tokenId_);
    }

    function settle(address operator_, uint256 tokenId_) external onlyPokeMe {
        Option storage option = _options[tokenId_];
        require(!option.settled, "already settled.");
        
        option.settled = true;
        
        uint256 poolId = _tokenIdToPoolId[tokenId_];
        require(poolId != 0, "!poolId");

        address poolAddress = _pools[poolId];
        require(poolAddress != address(0), "!poolAddress");
        OlympusProPool pool = OlympusProPool(poolAddress);
        _deleteAndBurn(tokenId_);

        pokeMe.cancelTask(option.pokeMe);
        pool.unlockTreasuryAmount1(address(this), option.tokensWillReceived);
    }

    function exercise(uint256 tokenId_)
        external onlyOptionOwner(tokenId_)
    {
        Option storage option = _options[tokenId_];
        require(!option.settled, "already settled.");
        
        option.settled = true;

        uint256 poolId = _tokenIdToPoolId[tokenId_];
        require(poolId != 0, "!poolId");

        address poolAddress = _pools[poolId];
        require(poolAddress != address(0), "!poolAddress");
        OlympusProPool pool = OlympusProPool(poolAddress);
        _deleteAndBurn(tokenId_);

        require(
            option.createTime + option.deadline < _blockTimestamp(),
            "not expired."
        );

        Terms memory poolTerms = _poolIdToTerms[poolId];
        require(poolTerms.token0 != address(0), "!token0");
        require(poolTerms.token1 != address(0), "!token1");
        require(
            option.createTime + option.deadline + poolTerms.timeBeforeDeadline >
                _blockTimestamp(),
            "deadline reached."
        );

        pokeMe.cancelTask(option.pokeMe);

        pool.getAssetNotional(msg.sender, option.notional);
        pool.payTokensWillReceived(address(this), msg.sender, option.tokensWillReceived);
    }

    /**
     * @notice Returns the maximum fee between the settlement and the exercise.
     */
    function _maxFee(uint256 instantFee_, uint256 debt_) private view returns (uint256 fee) {   
        require(instantFee_ != 0, "!instantFee_");
        require(debt_ != 0, "!debt_");
        uint256 fee = 0;
        if (instantFee_ != 0) {
            fee = _wmul(debt_, instantFee_);
        }
        require(fee >= 0, "fee detected is negative.");
    }    

    function getCumulatedFees(uint256 poolId_) external onlyManager {
        require(
            feeRecipient != address(0),
            "fee recipient address is not configured."
        );        
        require(poolId_ != 0, "Invalid pool ID");
           
        address poolAddress = _pools[poolId_];
        require(poolAddress != address(0), "!poolAddress");
        OlympusProPool pool = OlympusProPool(poolAddress);
        pool.getCumulatedFees(address(this), feeRecipient);
    }

    /**
     * @notice Returns the prime by market id.
     */
    function prime(uint256 debtRatio_, uint256 bcv_) public pure returns (uint256 prime) {
        prime = _wmul(debtRatio_, bcv_);
    }

    function options(uint256 tokenId_) external view returns (Option memory) {
        return _options[tokenId_];
    }

    function isOptionExpired(uint256 tokenId_) external view returns (bool) {
        Option storage option = _options[tokenId_];

        require(!option.settled, "already settled.");
        uint256 poolId = _tokenIdToPoolId[tokenId_];
        
           
        Terms memory poolTerms = _poolIdToTerms[poolId];
        require(poolTerms.token0 != address(0), "!token0");
        require(poolTerms.token1 != address(0), "!token1");

        uint256 currentTime = _blockTimestamp();
        if (
            option.createTime + option.deadline + poolTerms.timeBeforeDeadline >
            currentTime
        ) {
            return true;
        }
        return false;
    }

    modifier onlyPokeMe() {
        require(msg.sender == address(pokeMe), "only pokeMe");
        _;
    }

    modifier onlyOptionOwner(uint256 tokenId_) {  
        Option storage option = _options[tokenId_];
        require(msg.sender == option.operator, "only option owner");
        _;
    }
}
