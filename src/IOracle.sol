// SPDX-License-Identifier: MIT
pragma solidity > 0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title IOracle
 * @author Carla Montani
 * @notice Interface for oracle contracts that provide price feed data.
 * @dev Defines the standard interface for fetching the latest price answer.
 */
interface IOracle {
    /// @notice Returns the latest price answer from the oracle.
    /// @dev Should return the price with appropriate decimal scaling (typically 1e8).
    /// @return The latest price value as a signed integer.
    function latestAnswer() external view returns (int256);
}
