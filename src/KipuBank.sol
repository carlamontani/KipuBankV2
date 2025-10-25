// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

/**
 * @title KipuBank
 * @author Carla Montani
 * @notice This contract allows users to deposit and withdraw ETH under defined limits.
 * @dev Implements transaction limits, a global deposit cap, and individual balance tracking.
 */
contract KipuBank {

    /// @notice The maximum total amount of ETH the bank can store.
    uint256 internal immutable bankCap;

    /// @notice The maximum withdrawal limit per transaction.
    uint256 internal immutable MaximumWithdrawal = 5 ether;

    /// @notice Total number of deposits made in the contract.
    uint256 private TotalDepositsCount;

    /// @notice Total number of withdrawals made in the contract.
    uint256 private TotalWithdrawalsCount;

    /// @notice Total amount of ETH currently deposited in the contract.
    uint256 private TotalDepositsAmount;

    mapping(address => uint256) private _balance;
    mapping(address => uint256) private _depositCount;

    /// @notice Mapping of each user to their total number of withdrawals.
    mapping(address => uint256) private _withdrawalCount;

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

    /// @notice Thrown when total deposits exceed the bank’s capacity.
    /// @param totalDeposits The current total deposited amount.
    /// @param _bankCap The maximum allowed capacity.
    error BankCapacityExceeded(uint256 totalDeposits, uint256 _bankCap);

    /// @notice Ensures the provided amount is greater than zero.
    /// @param amount The amount to check.
    modifier NoZeroValue(uint256 amount) {
        if (amount == 0) revert ZeroAmount();
        _;
    }

    /// @notice Initializes the contract with a global deposit capacity limit.
    /// @param _bankCap The maximum total amount of ETH the bank can hold.
    constructor(uint256 _bankCap) {
        bankCap = _bankCap;
    }

    /// @notice Allows users to deposit ETH into their personal vault.
    /// @dev Requires a nonzero `msg.value`.
    /// @custom:error ZeroAmount Thrown if the deposit amount is zero.
    function Deposit() external payable NoZeroValue(msg.value) {
        _handleDeposit();
    }

    /// @notice Allows users to withdraw a specified amount of ETH.
    /// @param amount The amount to withdraw.
    /// @custom:error ExceedsMaximumWithdrawalLimit Thrown if the amount exceeds the per-transaction limit.
    /// @custom:error InsufficientBalance Thrown if the user has insufficient funds.
    /// @custom:error ZeroAmount Thrown if the withdrawal amount is zero.
    /// @custom:error TransferFailed Thrown if the ETH transfer fails.
    function Withdrawal(uint256 amount) external NoZeroValue(amount) {
        if (_balance[msg.sender] == 0) revert InsufficientBalance(0, amount);
        if (amount > MaximumWithdrawal)
            revert ExceedsMaximumWithdrawalLimit(amount, MaximumWithdrawal);
        if (amount > _balance[msg.sender])
            revert InsufficientBalance(_balance[msg.sender], amount);

        _balance[msg.sender] -= amount;
        _withdrawalCount[msg.sender]++;
        ++TotalWithdrawalsCount;
        TotalDepositsAmount -= amount;

        _transferEth(msg.sender, amount);

        emit MakeWithdrawal(msg.sender, amount);
    }

    /// @notice Returns the ETH balance of a given user.
    /// @param account The user’s address.
    /// @return The user’s current balance in wei.
    function GetBalance(address account) external view returns (uint256) {
        return _balance[account];
    }

    /// @notice Returns the number of deposits made by a specific user.
    /// @param account The user’s address.
    /// @return The total number of deposits.
    function GetDepositCount(address account) external view returns (uint256) { 
        return _depositCount[account];
    }

    /// @notice Returns the number of withdrawals made by a specific user.
    /// @param account The user’s address.
    /// @return The total number of withdrawals.
    function GetWithdrawalCount(address account) external view returns (uint256) {
        return _withdrawalCount[account];
    }

    /// @notice Handles the deposit logic.
    /// @dev Adds the deposited amount to the user’s balance and updates global counters.
    /// @custom:error BankCapacityExceeded Thrown if the bank’s total deposits exceed its capacity.
    function _handleDeposit() internal {
        if (TotalDepositsAmount + msg.value > bankCap)
            revert BankCapacityExceeded(TotalDepositsAmount, bankCap);

        _balance[msg.sender] += msg.value;
        _depositCount[msg.sender]++;
        ++TotalDepositsCount;
        TotalDepositsAmount += msg.value;

        emit MakeDeposit(msg.sender, msg.value);
    }

    /// @notice Transfers ETH safely to a given address.
    /// @param to The recipient address.
    /// @param amount The amount to send in wei.
    /// @return data The returned data from the low-level call.
    function _transferEth(address to, uint256 amount)
        private
        returns (bytes memory)
    {
        (bool success, bytes memory data) = to.call{value: amount}("");
        if (!success) revert TransferFailed(data);
        return data;
    }

    /// @notice Enables the contract to receive ETH directly.
    /// @dev Automatically treats any received ETH as a deposit.
    receive() external payable {
        if (msg.value == 0) revert ZeroAmount();
        _handleDeposit();
    }

    /// @notice Handles calls to non-existent functions.
    /// @dev If ETH is sent without data, it acts as a deposit. If invalid data is sent, it reverts.
    fallback() external payable {
        if (msg.data.length > 0 && msg.value == 0)
            revert TransferFailed("Invalid function call");
        if (msg.value == 0) revert ZeroAmount();
        _handleDeposit();
    }
}
