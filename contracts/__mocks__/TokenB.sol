
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @custom:dev 18 decimals token
contract TokenB is ERC20 {
    constructor() ERC20("Token B", "TKNB") {
        _mint(msg.sender, 1e27);
    }
}
