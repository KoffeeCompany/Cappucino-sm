// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;


interface IOlympusProPool {
    function lockTreasuryAmount1(address receiver_, uint256 debt_, uint256 fee_) external;
    function unlockTreasuryAmount1(address payer_, uint256 debt_) external;
    function getPrimeAmount1(address buyer_, address receiver_, uint256 prime_, uint256 notional_) external;
    function getAssetNotional(address operator_, uint256 notional_) external;
    function payTokensWillReceived(address payer_, address receiver_, uint256 amount_) external;
    function setTreasury(address newTreasury_) external;
    function setCapacity(uint256 newCapacity_) external;
    function setMaxPayout(uint256 newMaxPayout_) external;
    function setFee(uint256 newFee_) external;
    function setTimeBeforeDeadLine(uint256 timeBeforeDeadline_) external;
    function getCumulatedFees(address keeper_, address receiver_) external;
    function initialize(
        address treasury_,
        uint256 capacity_,
        uint256 maxPayout_,
        uint256 timeBeforeDeadline_,
        uint256 bcv_,
        uint256 fee_
    ) external;
    function debtRatio() external view returns (uint256);
    function balance0() external view returns (uint256);
    function balance1() external view returns (uint256);
}