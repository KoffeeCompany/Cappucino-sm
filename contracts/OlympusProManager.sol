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

abstract contract OlympusProManager is 
    Initializable,
    Proxied,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{  
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    // Privileged role that is able to select the option terms (strike price, expiry) to short
    address public manager;

    // Recipient for fees
    address public feeRecipient;

    string UNAUTHORIZED = "UNAUTHORIZED";

    event ManagerChanged(address oldManager, address newManager);
    event FeeRecipientChanged(address oldFeeRecipient, address newFeeRecipient);

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
     * @notice Sets the new fee recipient
     * @param newFeeRecipient_ is the address of the new fee recipient
     */
    function setFeeRecipient(address newFeeRecipient_) external onlyManager {
        require(
            newFeeRecipient_ != address(0) && newFeeRecipient_ != feeRecipient,
            "!newFeeRecipient"
        );
        address oldFeeRecipient = feeRecipient;
        feeRecipient = newFeeRecipient_;
        emit FeeRecipientChanged(oldFeeRecipient, feeRecipient);
    }
}