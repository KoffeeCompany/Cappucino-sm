// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "./BlockTimestamp.sol";

abstract contract ExpiryValidation is BlockTimestamp {
    modifier checkExpiry(uint256 deadline, uint256 delay) {
        require(_blockTimestamp() + delay <= deadline, 'Transaction too old');
        _;
    }
}