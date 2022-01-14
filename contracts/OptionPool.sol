// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {
    Initializable
} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {_wmul, _wdiv} from "./vendor/DSMath.sol";
import {Options, Option} from "./structs/SOption.sol";
import {OptionCanSettle} from "./structs/SOptionResolver.sol";
import {IPokeMe} from "./interfaces/IPokeMe.sol";
import {IOptionPoolFactory} from "./interfaces/IOptionPoolFactory.sol";
import {IPokeMeResolver} from "./IPokeMeResolver.sol";
import {
    _checkTokenNoAddressZero
} from "./checks/CheckFunctions.sol";

contract OptionPool is Ownable, Initializable {
    using SafeERC20 for IERC20;

    //#region IMMUTABLE PROPERTIES
    IERC20 public short;
    IERC20 public base;
    uint256 public expiryTime;
    uint256 public strike;
    //#endregion IMMUTABLE PROPERTIES

    uint256 public timeBeforeDeadLine;
    uint256 public bcv; // 18 decimal number
    IPokeMe public pokeMe;
    IPokeMeResolver public pokeMeResolver;

    uint256 public debt; // Increase during creation / Decrease during exercise
    uint256 public debtRatio; //  Call Option Debt Outstanding / Total Supply

    address private _receiver;
    address private _feeReceiver; // fee receiver, should be the Koffee community wallet
    uint256 private _feeRatio; // fee ratio
    uint256 public totalFees; // cumulated fees

    mapping(address => Options) public optionsByReceiver;

    IOptionPoolFactory public optionPoolFactory;

    //#region MODIFIERS

    modifier deadLineBeforeExpiry(
        uint256 expiryTime_,
        uint256 timeBeforeDeadLine_
    ) {
        require(
            expiryTime_ > timeBeforeDeadLine_,
            "OptionPool::initialize: timeBeforeDeadLine > expiryTime"
        );
        _;
    }

    modifier onlyPokeMe() {
        require(
            msg.sender == address(pokeMe),
            "OptionPool::onlyPokeMe: only pokeMe"
        );
        _;
    }

    modifier onlyReceiver() {        
        require(
            msg.sender == _receiver,
            "OptionPool::onlyReceiver: only receiver"
        );
        _;
    }

    //#endregion MODIFIERS

    //#region Events

    event LogOptionPool(
        address indexed pool,
        address short,
        address base,
        uint256 expiryTime,
        uint256 strike,
        uint256 timeBeforeDeadLine,
        uint256 bcv
    );

    event LogCreateOption(
        address indexed pool,
        uint256 indexed id,
        address short,
        address base,
        uint256 notional,
        uint256 amountOut,
        uint256 premium
    );

    event LogExerciseOption(
        address indexed pool,
        uint256 indexed id,
        uint256 amountIn
    );

    event LogSettle(
        address indexed pool,
        uint256 indexed id,
        address receiver
    );

    //#endregion Events

    // !!!!!!!!!!!!! CONSTRUCTOR !!!!!!!!!!!!!!!!

    constructor() Ownable() {
        optionPoolFactory = IOptionPoolFactory(msg.sender);
        _receiver = msg.sender;
    }

    // !!!!!!!!!!!!! CONSTRUCTOR !!!!!!!!!!!!!!!!

    function initialize(
        IERC20 short_,
        IERC20 base_,
        uint256 expiryTime_,
        uint256 strike_,
        uint256 timeBeforeDeadLine_,
        uint256 bcv_,
        IPokeMe pokeMe_,
        IPokeMeResolver pokeMeResolver_
    )
        public
        initializer
        deadLineBeforeExpiry(expiryTime_, timeBeforeDeadLine_)
    {
        short = short_;
        base = base_;
        expiryTime = expiryTime_;
        strike = strike_;
        timeBeforeDeadLine = timeBeforeDeadLine_;
        bcv = bcv_;
        pokeMe = pokeMe_;
        pokeMeResolver = pokeMeResolver_;

        emit LogOptionPool(
            address(this),
            address(short_),
            address(base_),
            expiryTime_,
            strike_,
            timeBeforeDeadLine_,
            bcv_
        );
    }

    //#region ONLY ADMIN

    function setTimeBeforeDeadLine(uint256 timeBeforeDeadLine_)
        external
        onlyOwner
        deadLineBeforeExpiry(expiryTime, timeBeforeDeadLine_)
    {
        timeBeforeDeadLine = timeBeforeDeadLine_;
    }

    function setBCV(uint256 bcv_) external onlyOwner {
        bcv = bcv_;
    }

    function increaseSupply(uint256 addend_) external onlyOwner {
        base.safeTransferFrom(msg.sender, address(this), addend_);
    }

    //#endregion ONLY ADMIN

    //#region ONLY RECEIVER  

    function setFeeReceiver(address feeReceiver_) external onlyReceiver {
        _feeReceiver = feeReceiver_;
    }

    function setFeeRatio(uint256 feeRatio_) external onlyReceiver {
        _feeRatio = feeRatio_;
    } 

    function getFees() external onlyReceiver {
        require(totalFees > 0, "OptionPool::getFees: no fees.");
        require(_feeReceiver != address(0), "OptionPool::getFees: fee receiver address is not configured.");
        base.safeTransferFrom(address(this), _feeReceiver, totalFees);
        totalFees = 0;
    }
    //#endregion ONLY RECEIVER

    function getPrice(uint256 amount_) public view returns (uint256) {
        return _wmul(_wmul(bcv, debtRatio), amount_);
    }

    //#region USER FUNCTIONS CREATE EXERCISE

    function create(uint256 notional_, address receiver_) external {
        address pool = address(this);
        Options storage options = optionsByReceiver[receiver_];

        Option memory option = Option({
            notional: notional_,
            receiver: receiver_,
            price: getPrice(notional_),
            startTime: block.timestamp,
            pokeMe: pokeMe.createTaskNoPrepayment(
                address(this),
                this.settle.selector,
                address(pokeMeResolver),
                abi.encodeWithSelector(
                    IPokeMeResolver.checker.selector,
                    OptionCanSettle({
                        pool: address(this),
                        receiver: receiver_,
                        id: options.opts.length
                    })
                ),
                address(short)
            ),
            settled: false
        });

        options.opts.push(option);
        options.nextID = options.opts.length;

        uint256 baseBalance = base.balanceOf(pool);

        debt += notional_;
        debtRatio = _wdiv(debt, baseBalance);

        uint256 fee = 0;
        if(_feeRatio != 0){
            _checkTokenNoAddressZero(_feeReceiver);
            fee = _wmul(notional_, _feeRatio);
        }

        require(fee >= 0, "OptionPool::create: fee detected is negative.");
        totalFees += fee;
        // add the fee into the debt and see if the protocol has enough as balance
        require(debt + totalFees <= baseBalance, "OptionPool::create: debt + totalFees > baseBalance.");

        uint256 balanceB = short.balanceOf(pool);

        short.safeTransferFrom(msg.sender, pool, option.price);

        assert(balanceB + option.price == short.balanceOf(pool));

        emit LogCreateOption(
            pool,
            options.nextID,
            address(short),
            address(base),
            notional_,
            _wmul(strike, notional_),
            option.price
        );
    }

    function exercise(uint256 id_) external {
        address pool = address(this);
        Options storage options = optionsByReceiver[msg.sender];

        Option storage option = options.opts[id_];

        require(!option.settled, "OptionPool::exercise: already settled.");
        option.settled = true;

        require(
            option.startTime + expiryTime < block.timestamp,
            "OptionPool::exercise: not expired."
        );

        require(
            option.startTime + expiryTime + timeBeforeDeadLine >
                block.timestamp,
            "OptionPool::exercise: deadline reached."
        );

        debt -= option.notional;
        debtRatio = _wdiv(debt, base.balanceOf(pool) - option.notional);
        pokeMe.cancelTask(option.pokeMe);

        uint256 balanceB = short.balanceOf(pool);

        uint256 amountIn = _wmul(option.notional, strike);

        short.safeTransferFrom(msg.sender, pool, amountIn);
        base.safeTransfer(msg.sender, option.notional);

        assert(balanceB + amountIn == short.balanceOf(pool));

        emit LogExerciseOption(pool, id_, amountIn);
    }

    function settle(address receiver_, uint256 id_) public onlyPokeMe {
        Options storage options = optionsByReceiver[receiver_];

        Option storage option = options.opts[id_];

        require(!option.settled, "OptionPool::exercise: already settled.");

        option.settled = true;
        pokeMe.cancelTask(option.pokeMe);

        emit LogSettle(address(this), id_, receiver_);
    }

    //#endregion USER FUNCTIONS CREATE EXERCISE

    //#region VIEW FUNCTIONS

    function getNextID(address receiver_) external view returns (uint256) {
        return optionsByReceiver[receiver_].nextID;
    }

    function getOptionOfReceiver(address receiver_, uint256 id_)
        external
        view
        returns (Option memory)
    {
        return optionsByReceiver[receiver_].opts[id_];
    }

    //#endregion VIEW FUNCTIONS
}
