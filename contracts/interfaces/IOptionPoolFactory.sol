// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import {IPokeMe} from "../interfaces/IPokeMe.sol";

interface IOptionPoolFactory {
    function pokeMe() external view returns (IPokeMe);
}