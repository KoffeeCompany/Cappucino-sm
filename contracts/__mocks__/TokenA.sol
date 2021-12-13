// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @custom:dev 18 decimals token
contract TokenA is ERC20 {
    constructor() ERC20("Token A", "TKNA") {
        _mint(msg.sender, 1e27);
    }
}
