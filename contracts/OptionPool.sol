// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

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

    uint256 public debt; // Increase during creation / Decrease during exercise
    uint256 public debtRatio; //  Call Option Debt Outstanding / Total Supply

    mapping(address => Options) public optionsByReceiver;

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

    //#endregion MODIFIERS

    //#region Events

    event CreateOption(
        address indexed pool,
        uint256 indexed id,
        address short,
        address base,
        uint256 notional,
        uint256 amountIn,
        uint256 price
    );

    event ExerciseOption(
        address indexed pool,
        uint256 indexed id,
        uint256 amountIn
    );

    //#endregion Events

    function initialize(
        IERC20 short_,
        IERC20 base_,
        uint256 expiryTime_,
        uint256 strike_,
        uint256 timeBeforeDeadLine_,
        uint256 bcv_
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

    function increaseTotalSupply(uint256 addend_) external onlyOwner {
        base.safeTransferFrom(msg.sender, address(this), addend_);
    }

    //#endregion ONLY ADMIN

    function getPrice() public view returns (uint256) {
        return _wmul(bcv, debtRatio);
    }

    //#region USER FUNCTIONS CREATE EXERCISE

    function create(uint256 notional_, address receiver_) external {
        address pool = address(this);
        Options storage options = optionsByReceiver[receiver_];

        Option memory option = Option({
            notional: notional_,
            receiver: receiver_,
            price: getPrice()
        });

        options.opts[options.nextID] = option;
        options.nextID++;

        uint256 baseBalance = base.balanceOf(pool);

        debt += notional_;
        debtRatio = _wdiv(debt, baseBalance);

        require(debt <= baseBalance, "OptionPool::create: debt > baseBalance.");

        uint256 balanceB = short.balanceOf(pool);

        uint256 amountIn = _wmul(notional_, option.price);

        short.safeTransferFrom(msg.sender, pool, amountIn);

        assert(balanceB + amountIn == short.balanceOf(pool));

        emit CreateOption(
            pool,
            options.nextID,
            address(short),
            address(base),
            notional_,
            amountIn,
            option.price
        );
    }

    function exercise(uint256 id_) external {
        address pool = address(this);
        Options storage options = optionsByReceiver[msg.sender];

        Option memory option = options.opts[id_];

        debt -= option.notional;
        debtRatio = _wdiv(debt, base.balanceOf(pool) - option.notional);

        uint256 balanceB = short.balanceOf(pool);

        uint256 amountIn = _wmul(option.notional, strike);

        short.safeTransferFrom(msg.sender, pool, amountIn);
        base.safeTransfer(msg.sender, option.notional);

        assert(balanceB + amountIn == short.balanceOf(pool));

        emit ExerciseOption(pool, id_, amountIn);
    }

    //#endregion USER FUNCTIONS CREATE EXERCISE
}
