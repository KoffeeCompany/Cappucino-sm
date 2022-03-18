// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;
import {IPokeMe} from "../interfaces/IPokeMe.sol";

interface IOlympusProOptionFactory {
    function pokeMe() external view returns (IPokeMe);
}