
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {IOlympusProOption} from "./interfaces/IOlympusProOption.sol";
import {IPokeMeResolver} from "./interfaces/IPokeMeResolver.sol";
import {Option} from "./structs/SOption.sol";

contract PokeMeResolver is IPokeMeResolver {
    function checker(SettleParams memory params_)
        public
        view
        returns (bool, bytes memory data)
    {
        IOlympusProOption opo = IOlympusProOption(params_.optionAddress);

        Option memory option = opo.options(params_.tokenId);

        if (opo.isOptionExpired(params_.tokenId) &&
            option.settled
        )
            return (
                false,
                abi.encodeWithSelector(
                    IOlympusProOption.settle.selector,
                    params_.operator,
                    params_.tokenId
                )
            );

        return (
            true,
            abi.encodeWithSelector(
                IOlympusProOption.settle.selector,
                params_.operator,
                params_.tokenId
            )
        );
    }
}
