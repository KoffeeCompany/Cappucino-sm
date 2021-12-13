// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {OptionCanSettle} from "./structs/SOptionResolver.sol";
import {Option} from "./structs/SOption.sol";
import {IOptionPool} from "./IOptionPool.sol";


contract PokeMeResolver {
    function checker(OptionCanSettle memory optionCanSettle)
        public
        view
        returns (bool, bytes memory data)
    {
        IOptionPool pool = IOptionPool(optionCanSettle.pool);

        Option memory option = pool.optionsByReceiver(optionCanSettle.receiver
        ).opts[optionCanSettle.id];

        if (
            option.startTime + pool.expiryTime() + pool.timeBeforeDeadLine() >
            block.timestamp &&
            option.settled
        )
            return (
                false,
                abi.encodeWithSelector(
                    IOptionPool.settle.selector,
                    optionCanSettle.receiver,
                    optionCanSettle.id
                )
            );

        return (
            true,
            abi.encodeWithSelector(
                IOptionPool.settle.selector,
                optionCanSettle.receiver,
                optionCanSettle.id
            )
        );
    }
}
