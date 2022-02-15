// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {IOlympusProOption} from "./interfaces/IOlympusProOption.sol";
import {OlympusProOptionManager} from "./OlympusProOptionManager.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {BlockTimestamp} from "./bases/BlockTimestamp.sol";
import {ExpiryValidation} from "./bases/ExpiryValidation.sol";
import {IBondDepository} from "./interfaces/Olympus/IBondDepository.sol";
import {IPokeMe} from "./interfaces/IPokeMe.sol";
import {IPokeMeResolver} from "./interfaces/IPokeMeResolver.sol";
import {
    _add,
    _wmul,
    _wdiv,
    _smul,
    _sdiv,
    _omul,
    _odiv
} from "./vendor/DSMath.sol";
import "hardhat/console.sol";

contract OlympusProOption is
    IOlympusProOption,
    BlockTimestamp,
    ExpiryValidation,
    OlympusProOptionManager
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public immutable olympusPool;
    address public immutable bondDepository;
    IPokeMe public pokeMe;
    IPokeMeResolver public pokeMeResolver;

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
        // the fee
        uint256 fee;
        // how many tokens user will get
        uint256 tokensWillReceived;
        uint256 deadline;
        uint256 createTime;
        bytes32 pokeMe;
        bool settled;
    }

    struct OptionSettlement {
        address operator;
        uint256 tokenId;
    }

    /// @dev The market ID option data by user address
    mapping(uint256 => Option) private _options;

    /// @dev The ID of the next token that will be minted. Skips 0
    uint176 private _nextId = 1;

    /**
     * @notice Initializes the contract with immutable variables
     * @param baseToken_ is the asset used for collateral
     * @param quoteToken_ is the asset used for premiums and result asset
     * @param factory_ is the option factory contract address
     * @param olympusPool_ is the Olympus pool address
     * @param bondDepository_ is the bonddepository address
     */
    constructor(
        address baseToken_,
        address quoteToken_,
        address factory_,
        address olympusPool_,
        address bondDepository_
    ) {
        require(baseToken_ != address(0), "!baseToken_");
        require(quoteToken_ != address(0), "!quoteToken_");
        require(factory_ != address(0), "!factory_");
        require(olympusPool_ != address(0), "!olympusPool_");
        require(bondDepository_ != address(0), "!bondDepository_");

        asset = quoteToken_;
        underlying = baseToken_;
        olympusPool = olympusPool_;
        bondDepository = bondDepository_;
        totalFees = 0;

        // hardcode the initial exercise fee and settle fee
        instantFee = _wdiv(5, 10 ** 3);
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
        uint256 bcv_,
        IPokeMe pokeMe_,
        IPokeMeResolver pokeMeResolver_
    ) external initializer {
        require(owner_ != address(0), "!owner_");
        require(timeBeforeDeadLine_ != 0, "!timeBeforeDeadLine_");
        require(bcv_ != 0, "!bcv_");

        __ReentrancyGuard_init();
        __Ownable_init();
        transferOwnership(owner_);
        __ERC721_init("Olympus Option NFT-V1", "OHM-OPT");

        // hardcode the initial exercise fee and settle fee
        instantFee = _wdiv(5, 1000);

        _marketId = marketId_;
        _bcv = bcv_;

        pokeMe = pokeMe_;
        pokeMeResolver = pokeMeResolver_;

        timeBeforeDeadline = timeBeforeDeadLine_;
    }

    /**
     * @notice Buy the option.
     * @param params mint parameter composed by :
     * recipient is the buyer of the contract who pay the premium
     * notional is the amount of quote token to spend
     * deadline is the option expiry time
     * strike is the price at which to exercise option
     */
    function buy(BuyParams calldata params)
        external
        payable
        nonReentrant
        checkExpiry(params.deadline, timeBeforeDeadline)
        returns (uint256 tokenId)
    {
        require(params.notional != 0, "OlympusProOption::buy: !notional");
        require(params.strike != 0, "OlympusProOption::buy: !strike");

        uint256 olympusBalance = olympusUnderlyingBalance();
        uint256 debt = _wmul(params.notional, params.strike);
        uint256 fee = maxFee(debt);
        totalFees += fee;

        require(debt + fee <= olympusBalance, "debt + fee > olympusBalance.");
        // lock the return amount from olympus pool
        IERC20(underlying).safeTransferFrom(
            olympusPool,
            address(this),
            _add(debt, fee)
        );

        // lock the premium amount from the user
        // TODO check if prime has notional precision.
        // Should be set that way during initialization?
        uint256 prime = prime();
        IERC20(underlying).safeTransferFrom(
            msg.sender,
            address(this),
            getPremium(address(underlying), prime, params.notional)
        );
        _safeMint(msg.sender, (tokenId = _nextId++));

        OptionParams memory opar = OptionParams({
            notional: params.notional,
            recipient: msg.sender,
            strike: params.strike,
            fee: fee,
            tokensWillReceived: debt,
            asset: asset,
            underlying: underlying,
            tokenId: tokenId,
            deadline: params.deadline
        });
        _options[tokenId] = _createOption(opar);
    }

    function _createOption(OptionParams memory params)
        private
        returns (Option memory)
    {
        return
            Option({
                notional: params.notional,
                operator: params.recipient,
                strike: params.strike,
                deadline: params.deadline,
                createTime: _blockTimestamp(),
                fee: params.fee,
                tokensWillReceived: params.tokensWillReceived,
                pokeMe: pokeMe.createTaskNoPrepayment(
                    address(this),
                    this.settle.selector,
                    address(pokeMeResolver),
                    abi.encodeWithSelector(
                        IPokeMeResolver.checker.selector,
                        OptionSettlement({
                            operator: params.recipient,
                            tokenId: params.tokenId
                        })
                    ),
                    params.underlying
                ),
                settled: false
            });
    }

    function burn(uint256 tokenId_)
        external
        payable
        isAuthorizedForToken(tokenId_)
    {
        Option storage option = _options[tokenId_];
        delete _options[tokenId_];
        _burn(tokenId_);
    }

    function settle(address operator_, uint256 tokenId_) public onlyPokeMe {
        Option storage option = _options[tokenId_];

        require(!option.settled, "already settled.");

        option.settled = true;
        pokeMe.cancelTask(option.pokeMe);
        IERC20(underlying).safeTransfer(olympusPool, option.tokensWillReceived);
    }

    function exercise(uint256 tokenId_)
        external
        payable
        isAuthorizedForToken(tokenId_)
    {
        Option storage option = _options[tokenId_];

        require(!option.settled, "already settled.");
        option.settled = true;

        require(
            option.createTime + option.deadline < _blockTimestamp(),
            "not expired."
        );

        require(
            option.createTime + option.deadline + timeBeforeDeadline >
                _blockTimestamp(),
            "deadline reached."
        );

        pokeMe.cancelTask(option.pokeMe);

        IERC20(asset).safeTransferFrom(
            msg.sender,
            olympusPool,
            option.notional
        );
        IERC20(underlying).safeTransfer(msg.sender, option.tokensWillReceived);
    }

    /**
     * @notice Returns the underlying balance on the olympus pool.
     */
    function olympusUnderlyingBalance() public view returns (uint256) {
        return IERC20(underlying).balanceOf(olympusPool);
    }

    /**
     * @notice Returns the maximum fee between the settlement and the exercise.
     */
    function maxFee(uint256 debt_) public view returns (uint256 fee) {
        uint256 fee = 0;
        if (instantFee != 0) {
            fee = _wmul(debt_, instantFee);
        }
        require(fee >= 0, "fee detected is negative.");
    }

    /**
     * @notice Returns the prime by market id.
     */
    function prime() public view returns (uint256 prime) {
        IBondDepository bond = IBondDepository(bondDepository);
        uint256 debtRatio = bond.debtRatio(_marketId);
        prime = _wmul(debtRatio, _bcv);
    }

    function getPremium(
        address _token,
        uint256 _prime,
        uint256 _notional
    ) internal view returns (uint256 premium) {
        uint8 decimals = ERC20(_token).decimals();

        if (decimals == 18) return _wmul(_prime, _notional);
        if (decimals == 6) return _smul(_prime, _notional);
        if (decimals == 8) return _omul(_prime, _notional);

        revert("OlympusProOption::getPremium: unsupported token precision.");
    }

    modifier onlyPokeMe() {
        require(msg.sender == address(pokeMe), "only pokeMe");
        _;
    }
}
