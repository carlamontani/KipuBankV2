// SPDX-License-Identifier: MIT
pragma solidity > 0.8.0;

import "./BankBase.sol";
import "./IOracle.sol";

/**
 * @title KipuBankV2
 * @author Carla Montani
 * @notice This contract allows users to deposit and withdraw ETH with price tracking in USD.
 * @dev Extends BankBase and integrates with a price oracle for ETH/USD conversion.
 */
contract KipuBank is BankBase {
    
    /// @notice Initializes the contract with a global deposit capacity limit and price oracle.
    /// @param _bankCap The maximum total amount of ETH the bank can hold.
    /// @param _oracle The oracle contract address for ETH price feeds.
    constructor(uint256 _bankCap, IOracle _oracle)
        BankBase(_bankCap, _oracle)
    {}
    
    /// @notice Allows users to deposit ETH into their personal vault.
    /// @dev Requires a nonzero `msg.value`. Updates both ETH balance and USD equivalent.
    /// @custom:error ZeroAmount Thrown if the deposit amount is zero.
    function deposit() external payable NoZeroValue(msg.value) {
        _balanceETH[msg.sender] += msg.value;
        balance[msg.sender].eth += msg.value;
        int256 ethPrice = _getETHPrice();
        if (ethPrice > 0) {
            balance[msg.sender].totalUSD += (msg.value * uint256(ethPrice)) / 1e8;
        }
        _updateDepositCounters(msg.sender, msg.value);
        emit MakeDeposit(msg.sender, msg.value);
    }
    
    /// @notice Allows users to withdraw a specified amount of ETH.
    /// @param amount The amount to withdraw in wei.
    /// @dev Updates ETH balance and transfers funds to the user.
    /// @custom:error ExceedsMaximumWithdrawalLimit Thrown if the amount exceeds the per-transaction limit.
    /// @custom:error InsufficientBalance Thrown if the user has insufficient funds.
    /// @custom:error ZeroAmount Thrown if the withdrawal amount is zero.
    /// @custom:error TransferFailed Thrown if the ETH transfer fails.
    function withdraw(uint256 amount) external NoZeroValue(amount) {
        if (amount > MAXIMUM_WITHDRAWAL)
            revert ExceedsMaximumWithdrawalLimit(amount, MAXIMUM_WITHDRAWAL);
        if (_balanceETH[msg.sender] < amount)
            revert InsufficientBalance(_balanceETH[msg.sender], amount);
        _balanceETH[msg.sender] -= amount;
        balance[msg.sender].eth -= amount;
        _updateWithdrawalCounters(msg.sender);
        _transferEth(msg.sender, amount);
        emit MakeWithdrawal(msg.sender, amount);
    }
    
    /// @notice Returns the current ETH price in USD from the oracle.
    /// @dev Overrides the base contract's virtual function.
    /// @return The current ETH price in USD (scaled by 1e8).
    function getCurrentETHPrice() external view override returns (int256) {
        return _getETHPrice();
    }
    
    /// @notice Enables the contract to receive ETH directly.
    /// @dev Automatically credits the sender's ETH balance without updating USD value or counters.
    receive() external payable {
        _balanceETH[msg.sender] += msg.value;
    }
}
