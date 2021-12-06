// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {_wdiv, _wmul} from "../vendor/DSMath.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract OptionPoolMock is Ownable {
    using SafeERC20 for IERC20;

    // !!!!!!!!!!!!! STRUCTS !!!!!!!!!!!!

    struct Option {
        uint256 amountOut;
        uint256 amountIn;
        uint256 expiry;
    }

    // !!!!!!!!!!!!! STRUCTS !!!!!!!!!!!!

    // !!!!!!!!!!!!! EVENTS !!!!!!!!!!!!!

    event LogOptionCreation(
        uint256 indexed id,
        address indexed pool,
        uint256 notional,
        uint256 amountOut,
        uint256 amountIn
    );

    event LogExercise(address indexed pool, address indexed user, uint256 id);

    // !!!!!!!!!!!!! EVENTS !!!!!!!!!!!!!

    address public immutable base;
    address public immutable short;
    string public optionType;
    uint256 public immutable liquidity;
    uint256 public immutable bcv;
    uint256 public immutable strike;
    uint256 public immutable maturity;

    uint256 public debt;
    uint256 public debtRatio;

    mapping(address => Option[]) optionsByUser;

    constructor(
        address base_,
        address short_,
        string memory optionType_,
        uint256 liquidity_,
        uint256 bcv_,
        uint256 strike_,
        uint256 maturity_
    ) {
        base = base_;
        short = short_;
        optionType = optionType_;
        liquidity = liquidity_;
        bcv = bcv_;
        strike = strike_;
        maturity = maturity_;
    }

    // !!!!!!! ADMIN FUNCTION !!!!!!!!!!!!

    function addLiquidity(uint256 addend_) external onlyOwner {
        IERC20(base).safeTransferFrom(msg.sender, address(this), addend_);
    }

    // !!!!!!! ADMIN FUNCTION !!!!!!!!!!!!

    // !!!!!!!! USER FUNCTIONS !!!!!!!!!!!

    function createOption(uint256 notional_) external {
        uint256 premium = getPrice(notional_);
        uint256 amountOut = _wmul(notional_, strike);
        debt += amountOut;
        debtRatio = _wdiv(debt, IERC20(base).balanceOf(address(this)));

        Option memory option = Option({
            amountOut: amountOut,
            amountIn: notional_,
            expiry: block.timestamp + maturity
        });

        optionsByUser[msg.sender].push(option);

        IERC20(short).safeTransferFrom(msg.sender, address(this), premium);

        emit LogOptionCreation(
            optionsByUser[msg.sender].length - 1,
            address(this),
            notional_,
            amountOut,
            notional_
        );
    }

    function exercise(uint256 id_) external {
        require(optionsByUser[msg.sender][id_].expiry < block.timestamp);

        IERC20(short).safeTransferFrom(
            msg.sender,
            address(this),
            optionsByUser[msg.sender][id_].amountIn
        );

        IERC20(base).safeTransfer(
            msg.sender,
            optionsByUser[msg.sender][id_].amountOut
        );

        emit LogExercise(address(this), msg.sender, id_);
    }

    // !!!!!!!! USER FUNCTIONS !!!!!!!!!!!

    // !!!!!!!! VIEW FUNCTION !!!!!!!!!!!!

    function getPrice(uint256 amount_) public view returns (uint256) {
        return _wmul(_wmul(bcv, debtRatio), amount_);
    }

    // !!!!!!!! VIEW FUNCTION !!!!!!!!!!!!
}
