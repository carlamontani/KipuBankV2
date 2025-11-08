// SPDX-License-Identifier: MIT
pragma solidity > 0.8.0;

import "./BankBase.sol";

/**
 * @title KipuBankV2
 * @author Carla Montani
 * @notice This contract allows users to deposit and withdraw ETH with price tracking in USD.
 * @dev Extends BankBase and integrates with Chainlink price oracle for ETH/USD conversion.
 */
contract KipuBank is BankBase {
    
    /// @notice Initializes the contract with a global deposit capacity limit and price feed.
    /// @param _bankCap The maximum total amount of ETH the bank can hold.
    /// @param _priceFeed The Chainlink price feed contract for ETH/USD.
    constructor(uint256 _bankCap, AggregatorV3Interface _priceFeed)
        BankBase(_bankCap, _priceFeed)
    {}
    
    /// @notice Allows users to deposit ETH into their personal vault.
    /// @dev Requires a nonzero `msg.value`. Validates bank capacity and updates balances.
    /// @custom:error ZeroAmount Thrown if the deposit amount is zero.
    /// @custom:error BankCapacityExceeded Thrown if deposit would exceed bank cap.
    function deposit() external payable NoZeroValue(msg.value) {
        _handleDeposit(msg.sender, msg.value);
    }
    
    /// @notice Allows users to withdraw a specified amount of ETH.
    /// @param amount The amount to withdraw in wei.
    /// @dev Updates ETH balance and transfers funds to the user.
    /// Caches storage variables in memory to minimize state access.
    /// @custom:error ExceedsMaximumWithdrawalLimit Thrown if the amount exceeds the per-transaction limit.
    /// @custom:error InsufficientBalance Thrown if the user has insufficient funds.
    /// @custom:error ZeroAmount Thrown if the withdrawal amount is zero.
    /// @custom:error TransferFailed Thrown if the ETH transfer fails.
    function withdraw(uint256 amount) external NoZeroValue(amount) {
        if (amount > MAXIMUM_WITHDRAWAL)
            revert ExceedsMaximumWithdrawalLimit(amount, MAXIMUM_WITHDRAWAL);
        
        uint256 userBalance = _balanceETH[msg.sender];
        if (userBalance < amount)
            revert InsufficientBalance(userBalance, amount);
        
        _balanceETH[msg.sender] = userBalance - amount;
        balance[msg.sender].eth -= amount;
        _updateWithdrawalCounters(msg.sender);
        _transferEth(msg.sender, amount);
        
        unchecked {
            totalDepositsAmount -= amount;
        }
        
        emit MakeWithdrawal(msg.sender, amount);
    }
    
    /// @notice Returns the current ETH price in USD from the oracle.
    /// @dev Overrides the base contract's virtual function.
    /// @return The current ETH price in USD (scaled by 1e8).
    function getCurrentETHPrice() external view override returns (int256) {
        return _getETHPrice();
    }
    
    /// @notice Enables the contract to receive ETH directly via transfers.
    /// @dev Calls _handleDeposit to validate bank capacity and update all state.
    /// @custom:error ZeroAmount Thrown if ETH sent is zero.
    /// @custom:error BankCapacityExceeded Thrown if deposit would exceed bank cap.
    receive() external payable NoZeroValue(msg.value) {
        _handleDeposit(msg.sender, msg.value);
    }
}
