// SPDX-License-Identifier: MIT
pragma solidity > 0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title BankBase
 * @author Carla Montani
 * @notice Base contract providing core banking functionality with ETH/USD tracking.
 * @dev Abstract contract that manages deposits, withdrawals, balances, and oracle integration.
 */
abstract contract BankBase is Ownable {
    /// @notice Struct to store user balance information in ETH and USD.
    /// @dev totalUSD is calculated based on ETH price at deposit time (scaled by 1e8).
    struct Balances {
        uint256 eth;
        uint256 totalUSD;
    }

    /// @notice Chainlink price feed aggregator for ETH/USD.
    /// @dev Public interface to interact with Chainlink's price oracle.
    AggregatorV3Interface public priceFeed;
    
    /// @notice The maximum total amount of ETH the bank can store.
    /// @dev Set at deployment and cannot be changed (immutable).
    uint256 internal immutable bankCap;
    
    /// @notice The maximum withdrawal limit per transaction.
    /// @dev Fixed at 5 ETH to prevent large single withdrawals.
    uint256 internal immutable MAXIMUM_WITHDRAWAL = 5 ether;

    /// @notice Total number of deposits made in the contract.
    /// @dev Incremented with each successful deposit across all users.
    uint256 internal totalDepositsCount;
    
    /// @notice Total number of withdrawals made in the contract.
    /// @dev Incremented with each successful withdrawal across all users.
    uint256 internal totalWithdrawalsCount;
    
    /// @notice Total amount of ETH currently deposited in the contract.
    /// @dev Updated on deposits (increases) and withdrawals (decreases).
    uint256 internal totalDepositsAmount;

    /// @notice Mapping of each user's address to their ETH balance.
    /// @dev Tracks individual ETH balances, updated on deposits and withdrawals.
    mapping(address => uint256) internal _balanceETH;
    
    /// @notice Mapping of each user's address to their total number of deposits.
    /// @dev Incremented each time a user makes a deposit.
    mapping(address => uint256) internal _depositCount;
    
    /// @notice Mapping of each user to their total number of withdrawals.
    /// @dev Incremented each time a user makes a withdrawal.
    mapping(address => uint256) internal _withdrawalCount;
    
    /// @notice Mapping of each user's address to their complete balance information.
    /// @dev Contains both ETH balance and USD equivalent value.
    mapping(address => Balances) public balance;

    event MakeDeposit(address indexed account, uint256 amount);
    event MakeWithdrawal(address indexed account, uint256 amount);

    /// @notice Thrown when the amount exceeds the maximum withdrawal limit.
    /// @param amount The requested withdrawal amount.
    /// @param limit The maximum allowed withdrawal amount.
    error ExceedsMaximumWithdrawalLimit(uint256 amount, uint256 limit);
    
    /// @notice Thrown when a user attempts to withdraw more than their balance.
    /// @param _balance The user's current balance.
    /// @param amount The requested withdrawal amount.
    error InsufficientBalance(uint256 _balance, uint256 amount);
    
    /// @notice Thrown when the provided or sent amount is zero.
    error ZeroAmount();
    
    /// @notice Thrown when a transfer of ETH fails.
    /// @param reason The returned data from the failed call.
    error TransferFailed(bytes reason);
    
    /// @notice Thrown when total deposits exceed the bank's capacity.
    /// @param totalDeposits The current total deposited amount.
    /// @param _bankCap The maximum allowed capacity.
    error BankCapacityExceeded(uint256 totalDeposits, uint256 _bankCap);

    /// @notice Ensures the provided amount is greater than zero.
    /// @param amount The amount to check.
    modifier NoZeroValue(uint256 amount) {
        if (amount == 0) revert ZeroAmount();
        _;
    }

    /// @notice Initializes the base contract with capacity limit and price feed.
    /// @param _bankCap The maximum total amount of ETH the bank can hold.
    /// @param _priceFeed The Chainlink price feed contract for ETH/USD.
    constructor(uint256 _bankCap, AggregatorV3Interface _priceFeed) Ownable(msg.sender) {
        bankCap = _bankCap;
        priceFeed = _priceFeed;
    }

    /// @notice Fetches the current ETH price from the Chainlink oracle.
    /// @dev Internal function that queries the price feed contract.
    /// @return The current ETH price in USD (scaled by 1e8).
    function _getETHPrice() internal view returns (int256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return answer;
    }

    /// @notice Transfers ETH safely to a given address.
    /// @param to The recipient address.
    /// @param amount The amount to send in wei.
    /// @return data The returned data from the low-level call.
    /// @dev Uses low-level call to transfer ETH and reverts on failure.
    function _transferEth(address to, uint256 amount) internal returns (bytes memory) {
        (bool success, bytes memory data) = to.call{value: amount}("");
        if (!success) revert TransferFailed(data);
        return data;
    }

    /// @notice Internal deposit handler that validates bank capacity and updates all state.
    /// @param account The address of the depositor.
    /// @param amount The amount being deposited.
    /// @dev Checks bank cap before updating balances and counters. Uses unchecked for safe increments.
    /// Caches storage variable in memory to minimize state access.
    function _handleDeposit(address account, uint256 amount) internal {
        uint256 currentTotal = totalDepositsAmount;
        
        if (currentTotal + amount > bankCap)
            revert BankCapacityExceeded(currentTotal, bankCap);
        
        uint256 userBalance = _balanceETH[account];
        _balanceETH[account] = userBalance + amount;
        
        Balances storage userBalances = balance[account];
        userBalances.eth += amount;
        
        int256 ethPrice = _getETHPrice();
        if (ethPrice > 0) {
            userBalances.totalUSD += (amount * uint256(ethPrice)) / 1e8;
        }
        
        unchecked {
            _depositCount[account]++;
            totalDepositsCount++;
            totalDepositsAmount = currentTotal + amount;
        }
        
        emit MakeDeposit(account, amount);
    }

    /// @notice Updates withdrawal-related counters.
    /// @param account The address of the withdrawer.
    /// @dev Increments global and user-specific withdrawal counters using unchecked.
    function _updateWithdrawalCounters(address account) internal {
        unchecked {
            _withdrawalCount[account]++;
            totalWithdrawalsCount++;
        }
    }

    /// @notice Returns the current ETH price in USD from the oracle.
    /// @dev Virtual function that can be overridden by derived contracts.
    /// @return The current ETH price in USD (scaled by 1e8).
    function getCurrentETHPrice() external view virtual returns (int256) {
        return _getETHPrice();
    }

    /// @notice Returns the ETH balance of a given user.
    /// @param account The user's address.
    /// @return The user's current ETH balance in wei.
    function getBalance(address account) external view returns (uint256) {
        return _balanceETH[account];
    }

    /// @notice Returns the number of deposits made by a specific user.
    /// @param account The user's address.
    /// @return The total number of deposits.
    function getDepositCount(address account) external view returns (uint256) {
        return _depositCount[account];
    }

    /// @notice Returns the number of withdrawals made by a specific user.
    /// @param account The user's address.
    /// @return The total number of withdrawals.
    function getWithdrawalCount(address account) external view returns (uint256) {
        return _withdrawalCount[account];
    }

    /// @notice Returns the total amount of ETH deposited in the contract.
    /// @return The total deposited amount in wei.
    function getTotalDeposits() external view returns (uint256) {
        return totalDepositsAmount;
    }

    /// @notice Returns the total number of deposits made in the contract.
    /// @return The total count of all deposits.
    function getTotalDepositsCount() external view returns (uint256) {
        return totalDepositsCount;
    }

    /// @notice Returns the total number of withdrawals made in the contract.
    /// @return The total count of all withdrawals.
    function getTotalWithdrawalsCount() external view returns (uint256) {
        return totalWithdrawalsCount;
    }
}
