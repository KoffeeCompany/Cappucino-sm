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
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./vendor/DSMath.sol";

contract OlympusProOptionManager is 
    Initializable,
    Proxied,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC721Upgradeable {

    // Privileged role that is able to select the option terms (strike price, expiry) to short
    address public manager;

    // Fee incurred when exercising the option
    uint256 public instantExerciseFee;

    // Fee incurred when settle the option
    uint256 public instantSettleFee;
    
    // time before we consider the option is expired (1 day)
    uint256 public timeBeforeDeadline;

    // Recipient for withdrawal fees
    address public feeRecipient;

    string UNAUTHORIZED = "UNAUTHORIZED";

    event ManagerChanged(address oldManager, address newManager);
    event ExerciseFeeSet(uint256 oldFee, uint256 newFee);
    event SettleFeeSet(uint256 oldFee, uint256 newFee);

    modifier onlyManager() {
        require(msg.sender == manager, UNAUTHORIZED);
        _;
    }

    /**
     * @notice Sets the new manager.
     * @param newManager is the new manager
     */
    function setManager(address newManager) external onlyOwner {
        require(newManager != address(0), "!newManager");
        address oldManager = manager;
        manager = newManager;

        emit ManagerChanged(oldManager, newManager);
    }

    /**
     * @notice Sets the new exercise fee
     * @param newExerciseFee is the fee paid in tokens when exercising
     */
    function setExerciseFee(uint256 newExerciseFee) external onlyManager {
        require(newExerciseFee > 0, "exerciseFee != 0");

        // cap max exercise fees to 30% of the output amount
        require(newExerciseFee < _wdiv(3, 100), "exerciseFee >= 30%");

        uint256 oldFee = instantExerciseFee;
        emit ExerciseFeeSet(oldFee, newExerciseFee);

        instantExerciseFee = newExerciseFee;
    }

    /**
     * @notice Sets the new settlement fee
     * @param newSettleFee is the fee paid in tokens when settlement
     */
    function setSettleFee(uint256 newSettleFee) external onlyManager {
        require(newSettleFee > 0, "settleFee != 0");

        // cap max settle fees to 30% of the output amount
        require(newSettleFee < _wdiv(3, 100), "settleFee >= 30%");

        uint256 oldFee = instantSettleFee;
        emit SettleFeeSet(oldFee, newSettleFee);

        instantSettleFee = newSettleFee;
    }
}
