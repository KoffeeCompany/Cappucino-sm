// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import { IOlympusProPool } from "./interfaces/IOlympusProPool.sol";
import { OlympusProOptionFactory } from "./OlympusProOptionFactory.sol";
import { NoDelegateCall } from "./bases/NoDelegateCall.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
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
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract OlympusProPool is IOlympusProPool, 
    NoDelegateCall,
    Initializable,
    ReentrancyGuardUpgradeable,    
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public immutable factory;
    address public immutable token0;
    address public immutable token1;
    uint256 public immutable quoteDecimals;
    address public treasury;
    uint256 public capacity;
    uint256 public maxPayout;
    uint256 public totalDebt;
    uint256 public timeBeforeDeadline;
    uint256 public bcv;
    uint256 public instantFee;    

    // cumulated fees
    uint256 public totalFees; // cumulated fees
    
    event TreasuryChanged(address oldTreasury, address newTreasury);
    event CapacityChanged(uint256 oldCapacity, uint256 newCapacity);
    event MaxPayoutChanged(uint256 oldMaxPayout, uint256 newMaxPayout);
    event FeeChanged(uint256 oldFee, uint256 newFee);
    event TimeBeforeDeadLineChanged(
        uint256 oldTimeBeforeDeadLine,
        uint256 newTimeBeforeDeadLine
    );

    /**
     * @notice Initializes the contract with immutable variables
    /// @param factory_ The factory option address
    /// @param token0_ The first token of the pool
    /// @param token1_ The second token of the pool
    /// @param owner_ The pool owner 
     */
    constructor(
        address factory_,
        address token0_,
        address token1_,
        address owner_
    ) {             
        require(factory_ != address(0), "!factory_");
        require(token0_ != address(0), "!token0_");
        require(token1_ != address(0), "!token1_");
        require(owner_ != address(0), "!owner_");

        factory = factory_;
        token0 = token0_;
        token1 = token1_;
        quoteDecimals = ERC20(token1).decimals();

        __ReentrancyGuard_init();
        __Ownable_init();
        transferOwnership(owner_);
    }
    
    /**
     * @notice Initializes the contract with storage variables.
     * @param treasury_ The treasury address
     * @param capacity_ is the capacity of the pool
     * @param maxPayout_ is the max payout of the pool
     * @param timeBeforeDeadline_ is the option limit time
     * @param bcv_ is the bcv factor
     * @param fee_ is the fee ratio
     */
    function initialize(
        address treasury_,
        uint256 capacity_,
        uint256 maxPayout_,
        uint256 timeBeforeDeadline_,
        uint256 bcv_,
        uint256 fee_
    ) external initializer {
        require(treasury_ != address(0), "!treasury_");
        require(capacity_ != 0, "!capacity_");
        require(maxPayout_ != 0, "!maxPayout_");
        require(timeBeforeDeadline_ != 0, "!timeBeforeDeadline_");
        require(bcv_ != 0, "!bcv_");
        require(fee_ != 0, "!fee_");

        treasury = treasury_;
        bcv = bcv_;
        capacity = capacity_;
        maxPayout = maxPayout_;
        totalDebt = 0;
        totalFees = 0;
        timeBeforeDeadline = timeBeforeDeadline_;
        instantFee = fee_;
        require(capacity <= balanceOf(token1, treasury), "!balance size exceeded");
    }

    modifier onlyManager() {
        require(msg.sender == OlympusProOptionFactory(factory).owner());
        _;
    }

    /**
     * @notice Sets the new treasury
     * @param newTreasury_ is the address of the new treasury
     */
    function setTreasury(address newTreasury_) external onlyOwner {
        require(
            newTreasury_ != address(0) && newTreasury_ != treasury,
            "!newTreasury_"
        );
        address oldTreasury = treasury;
        treasury = newTreasury_;

        emit TreasuryChanged(oldTreasury, treasury);
    }

    /**
     * @notice Sets pool capacity
     * @param newCapacity_ is the new capacity of the pool
     */
    function setCapacity(uint256 newCapacity_) external onlyOwner {
        require(
            newCapacity_ != 0 && newCapacity_ != capacity,
            "!newCapacity_"
        );
        uint256 oldCapacity = capacity;
        capacity = newCapacity_;

        require(capacity <= _add(balanceOf(token1, treasury), totalDebt), "!balance size exceeded");

        emit CapacityChanged(oldCapacity, capacity);
    }

    /**
     * @notice Sets pool max payout
     * @param newMaxPayout_ is the new max payout of the pool
     */
    function setMaxPayout(uint256 newMaxPayout_) external onlyOwner {
        require(
            newMaxPayout_ != 0 && newMaxPayout_ != maxPayout,
            "!newMaxPayout_"
        );
        uint256 oldMaxPayout = maxPayout;
        maxPayout = newMaxPayout_;

        emit MaxPayoutChanged(oldMaxPayout, maxPayout);
    }

    /**
     * @notice Sets the new fee
     * @param newFee_ is the fee paid in tokens
     */
    function setFee(uint256 newFee_) external onlyManager {
        require(newFee_ > 0, "fee != 0");

        // cap max fees to 30% of the output amount
        require(newFee_ < _wdiv(3, 10**1), "fee >= 30%");

        uint256 oldFee = instantFee;
        emit FeeChanged(oldFee, newFee_);

        instantFee = newFee_;
    }

    function setTimeBeforeDeadLine(uint256 timeBeforeDeadline_)
        external
        onlyManager
    {
        require(timeBeforeDeadline_ != 0, "!timeBeforeDeadline.");
        uint256 oldTimeBeforeDeadLine = timeBeforeDeadline;
        emit TimeBeforeDeadLineChanged(oldTimeBeforeDeadLine, timeBeforeDeadline_);
        timeBeforeDeadline = timeBeforeDeadline_;
    }

    function lockTreasuryAmount1(address receiver_, uint256 debt_, uint256 fee_) external onlyManager
    {
        require(receiver_ != address(0), "!receiver_");
        require(debt_ != 0, "!debt_");
        require(fee_ != 0, "!fee_");

        uint256 payout = _add(debt_, fee_);
        totalFees += fee_;
        // markets have a max payout amount, capping size
        require(payout <= maxPayout, "max size exceeded");

        require(capacity <= _add(totalDebt, payout), "capacity pool exceeded");

        // incrementing total debt raises the price of the next option
        totalDebt += payout;

        IERC20(token1).safeTransferFrom(
            treasury,
            receiver_,
            payout
        );
    }

    function unlockTreasuryAmount1(address payer_, uint256 debt_) external onlyManager
    {
        require(payer_ != address(0), "!payer_");
        require(debt_ != 0, "!debt_");

        // markets have a max payout amount, capping size
        require(debt_ <= maxPayout, "max size exceeded");

        // deincrementing total debt raises the price of the next option
        totalDebt -= debt_;

        IERC20(token1).safeTransferFrom(
            payer_,
            treasury,
            debt_
        );
    }

    function getPrimeAmount1(address buyer_, address receiver_, uint256 prime_, uint256 notional_) external onlyManager
    {
        require(buyer_ != address(0), "!buyer_");
        require(receiver_ != address(0), "!receiver_");
        require(prime_ != 0, "!prime_");
        require(notional_ != 0, "!notional_");

        uint256 totalPrime;
        if (quoteDecimals == 18) totalPrime = _wmul(prime_, notional_);
        else if (quoteDecimals == 6) totalPrime =  _smul(prime_, notional_);
        else if (quoteDecimals == 8) totalPrime =  _omul(prime_, notional_);
        else revert("unsupported token precision.");

        // markets have a max payout amount, capping size
        require(totalPrime <= maxPayout, "max size exceeded");
        
        IERC20(token1).safeTransferFrom(
            buyer_,
            receiver_,
            totalPrime
        );
    }

    
    function getAssetNotional(address operator_, uint256 notional_) external onlyManager
    {
        require(operator_ != address(0), "!operator_");
        require(notional_ != 0, "!notional_");

        // markets have a max payout amount, capping size
        require(notional_ <= maxPayout, "max size exceeded");

        IERC20(token0).safeTransferFrom(
            operator_,
            treasury,
            notional_
        );
    }
    
    function payTokensWillReceived(address payer_, address receiver_, uint256 amount_) external onlyManager
    {
        require(payer_ != address(0), "!payer_");
        require(receiver_ != address(0), "!receiver_");
        require(amount_ != 0, "!amount_");

        // markets have a max payout amount, capping size
        require(amount_ <= maxPayout, "max size exceeded");

        IERC20(token0).safeTransferFrom(
            payer_,
            receiver_,
            amount_
        );
    }

    function getCumulatedFees(address keeper_, address receiver_) external onlyManager {
        require(
            keeper_ != address(0),
            "!keeper_"
        );
        require(receiver_ != address(0), "!receiver_");

        IERC20(token1).safeTransferFrom(
            keeper_,
            receiver_,
            totalFees
        );
        totalFees = 0;
    }

    /**
     * @notice             calculate current ratio of debt to supply
     * @dev                uses current debt
     * @return             debt ratio for market in quote decimals
     */
    function debtRatio() external view returns (uint256) {
        return  _wdiv(_wmul(totalDebt, quoteDecimals), capacity);
    }

    /// @dev Get the pool's balance of token0
    function balance0() external view returns (uint256) {
        return balanceOf(token0, treasury);
    }

    function balanceOf(address token, address where) private view returns(uint256) {
        require(where != address(0), "!where");
        require(token != address(0), "!token");
        return IERC20(token).balanceOf(where);
    }


    /// @dev Get the pool's balance of token1
    function balance1() external view returns (uint256) {
        return balanceOf(token1, treasury);
    }

}