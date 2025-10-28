// SPDX-License-Identifier: MIT
pragma solidity > 0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IOracle.sol";

/**
 * @title Oracle
 * @author Carla Montani
 * @notice This contract provides ETH/USD price feeds using Chainlink oracles.
 * @dev Implements the IOracle interface and wraps Chainlink's AggregatorV3Interface.
 */
contract Oracle is IOracle {
    /// @notice Chainlink price feed aggregator for ETH/USD.
    /// @dev Internal interface to interact with Chainlink's price oracle on Sepolia testnet.
    AggregatorV3Interface internal priceFeed;

    /// @notice Initializes the oracle with the Chainlink ETH/USD price feed on Sepolia.
    /// @dev Sets the price feed address to Chainlink's Sepolia ETH/USD aggregator.
    constructor() {
        priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306); // Sepolia ETH/USD
    }

    /// @notice Returns the latest round data from the Chainlink price feed.
    /// @dev Fetches complete round information including price, timestamps, and round IDs.
    /// @return roundId The round ID from the aggregator.
    /// @return answer The price answer (ETH/USD with 8 decimals).
    /// @return startedAt Timestamp when the round started.
    /// @return updatedAt Timestamp when the round was updated.
    /// @return answeredInRound The round ID in which the answer was computed.
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return priceFeed.latestRoundData();
    }

    /// @notice Returns only the latest ETH/USD price.
    /// @dev Simplified function that extracts only the price from latestRoundData.
    /// @return The current ETH price in USD (scaled by 1e8).
    function latestAnswer() external view returns (int256) {
        (, int256 answer,,,) = priceFeed.latestRoundData();
        return answer;
    }
}
