// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import './interfaces/INonfungiblePositionManager.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {Options, Option} from "./structs/SOption.sol";

contract NonfungiblePositionManager is INonfungiblePositionManager, ERC721 {
    
    /// @dev The hash of the name used in the permit signature verification
    bytes32 private immutable nameHash;

    /// @dev The hash of the version string used in the permit signature verification
    bytes32 private immutable versionHash;

    /// @notice Computes the nameHash and versionHash
    constructor(
        string memory name_,
        string memory symbol_,
        string memory version_
    ) ERC721(name_, symbol_) {
        nameHash = keccak256(bytes(name_));
        versionHash = keccak256(bytes(version_));
    }

    /// @inheritdoc INonfungiblePositionManager
    // function mint(MintParams calldata params)
    //     external
    //     payable
    //     returns (
    //         uint256 tokenId,
    //         uint128 liquidity,
    //         uint256 amount0,
    //         uint256 amount1
    //     )
    // {
    //     Option memory option = Option({
    //         notional: notional_,
    //         receiver: receiver_,
    //         price: getPrice(notional_),
    //         startTime: block.timestamp,
    //         pokeMe: pokeMe.createTaskNoPrepayment(
    //             address(this),
    //             this.settle.selector,
    //             address(pokeMeResolver),
    //             abi.encodeWithSelector(
    //                 IPokeMeResolver.checker.selector,
    //                 OptionCanSettle({
    //                     pool: address(this),
    //                     receiver: receiver_,
    //                     id: options.opts.length
    //                 })
    //             ),
    //             address(short)
    //         ),
    //         settled: false
    //     });
    // }
}
