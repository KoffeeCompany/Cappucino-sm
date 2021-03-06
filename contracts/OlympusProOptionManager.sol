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
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./vendor/DSMath.sol";

//import "hardhat/console.sol";

contract OlympusProOptionManager is
    Initializable,
    Proxied,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC721Upgradeable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public asset;
    address public underlying;
    // Privileged role that is able to select the option terms (strike price, expiry) to short
    address public manager;

    // Fee
    uint256 public instantFee;

    // time before we consider the option is expired (1 day)
    uint256 public timeBeforeDeadline;

    // Recipient for fees
    address public feeRecipient;

    // cumulated fees
    uint256 public totalFees; // cumulated fees

    string UNAUTHORIZED = "UNAUTHORIZED";

    event ManagerChanged(address oldManager, address newManager);
    event FeeSet(uint256 oldFee, uint256 newFee);
    event TimeBeforeDeadLineSet(
        uint256 oldTimeBeforeDeadLine,
        uint256 newTimeBeforeDeadLine
    );

    modifier onlyManager() {
        require(msg.sender == manager, UNAUTHORIZED);
        _;
    }

    /**
     * @notice Sets the new manager.
     * @param newManager_ is the new manager
     */
    function setManager(address newManager_) external onlyOwner {
        require(newManager_ != address(0), "!newManager");
        address oldManager = manager;
        manager = newManager_;

        emit ManagerChanged(oldManager, newManager_);
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
        emit FeeSet(oldFee, newFee_);

        instantFee = newFee_;
    }

    function getCumulatedFees() external onlyManager {
        require(totalFees > 0, "no fees.");
        require(
            feeRecipient != address(0),
            "fee recipient address is not configured."
        );
        IERC20(underlying).safeTransferFrom(
            address(this),
            feeRecipient,
            totalFees
        );
        totalFees = 0;
    }

    function setTimeBeforeDeadLine(uint256 timeBeforeDeadLine_)
        external
        onlyManager
    {
        require(timeBeforeDeadLine_ != 0, "!timeBeforeDeadLine.");
        uint256 oldTimeBeforeDeadLine = timeBeforeDeadline;
        emit TimeBeforeDeadLineSet(oldTimeBeforeDeadLine, timeBeforeDeadLine_);
        timeBeforeDeadline = timeBeforeDeadLine_;
    }

    /**
     * @notice Sets the new fee recipient
     * @param newFeeRecipient_ is the address of the new fee recipient
     */
    function setFeeRecipient(address newFeeRecipient_) external onlyManager {
        require(
            newFeeRecipient_ != address(0) && newFeeRecipient_ != feeRecipient,
            "!newFeeRecipient"
        );
        feeRecipient = newFeeRecipient_;
    }

    modifier isAuthorizedForToken(uint256 tokenId_) {
        require(_isApprovedOrOwner(msg.sender, tokenId_), "Not approved");
        _;
    }
}
