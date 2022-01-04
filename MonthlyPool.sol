// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GameLobby.sol";

/// @title FourPlayerGameLobby
/// @author Burtininkas69
/// @dev Creates lobby structure for games up to 4 players, winner of each game will take most of the pool.
/// @dev Precentage of pool gets divided for top players and dev team.

contract MonthlyPool is FourPlayerGameLobby {
    event DistributedWinnings(
        uint256,
        address indexed,
        address indexed,
        address indexed
    );

    address public firstPlace;
    address public secondPlace;
    address public thirdPlace;

    /// @notice How much time needs to be passed before picking top 3 players again.
    uint256 time = 60 minutes;
    uint256 lastBlock;

    /// @notice Percentages of top player pool share.
    uint8 percentageForFirst = 45;
    uint8 percentageForSecond = 35;
    uint8 percentageForThird = 20;

    /// @notice Finds best player (most wins) and places it into first place.
    function _assetFirstPlace() internal {
        address tempFirstPlace;

        for (uint256 i = 0; i < numberOfPlayers; i++) {
            address tempAddress = allPlayers[i];

            if (wins[tempAddress] > 0) {
                if (wins[tempAddress] > wins[allPlayers[i + 1]]) {
                    tempFirstPlace = tempAddress;
                }
            }
        }

        firstPlace = tempFirstPlace;
    }

    /// @notice Finds second best player (most wins) and places it into second place.
    function _assertSecondPlace() internal {
        address tempSecondPlace;

        for (uint256 i = 0; i < numberOfPlayers; i++) {
            if (allPlayers[i] != firstPlace) {
                address tempAddress = allPlayers[i];

                if (wins[tempAddress] > 0) {
                    if (wins[tempAddress] > wins[allPlayers[i + 1]]) {
                        tempSecondPlace = tempAddress;
                    }
                }
            }
        }

        secondPlace = tempSecondPlace;
    }

    /// @notice Finds third best player (most wins) and places it into third place.
    function _assetThirdPlace() internal {
        address tempThirdPlace;

        for (uint256 i = 0; i < numberOfPlayers; i++) {
            if (allPlayers[i] != firstPlace && allPlayers[i] != secondPlace) {
                address tempAddress = allPlayers[i];

                if (wins[tempAddress] > 0) {
                    if (wins[tempAddress] > wins[allPlayers[i + 1]]) {
                        tempThirdPlace = tempAddress;
                    }
                }
            }
        }

        thirdPlace = tempThirdPlace;
    }

    /// @notice Resets temporary stats for every player.
    function _resetTempStats() internal {
        for (uint256 i = 0; i < numberOfPlayers; i++) {
            address __tempPlayer = allPlayers[i];
            tempWins[__tempPlayer] = 0;
            tempLosses[__tempPlayer] = 0;
        }
    }

    /// @notice Picks up top 3 players
    function RefreshLeaderboard() public {
        _assetFirstPlace();
        _assertSecondPlace();
        _assetThirdPlace();
        _resetTempStats();
    }

    /// @notice Distributes winnings across top 3 players and clears pool / activates timer.
    function DistributeWinnings() public {
        require(block.timestamp >= lastBlock + time, "Needs more time");
        lastBlock = block.timestamp;
        balance[firstPlace] += (monthlyPool / 100) * percentageForFirst;
        balance[secondPlace] += (monthlyPool / 100) * percentageForSecond;
        balance[thirdPlace] += (monthlyPool / 100) * percentageForThird;
        emit DistributedWinnings(
            monthlyPool,
            firstPlace,
            secondPlace,
            thirdPlace
        );
        monthlyPool = 0;
    }
}
