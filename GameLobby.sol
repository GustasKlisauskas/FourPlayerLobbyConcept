// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title FourPlayerGameLobby
/// @author Burtininkas69
/// @dev Creates lobby structure for game up to 4 players

contract FourPlayerGameLobby {
    event NewGame(address indexed, uint256, uint256);
    event JoinedGame(address indexed, uint256);
    event Winner(address indexed, uint256);

    address nullAddress = 0x0000000000000000000000000000000000000000;
    address admin;

    /// @notice Percentage of each game goes to seperate pool for top players and dev team.
    uint8 monthlyPoolPct = 6;
    uint8 devWalletPct = 4;

    /// @notice Ether is used in creating game price. It let's user type value in ether, not wei.
    /// @dev This limits game floor price to 1 ether.
    uint256 Eth = 1 ether;
    uint256 public devWallet;
    uint256 public monthlyPool;
    uint256 numberOfPlayers;

    /// @dev Array used to get all players addresses to add to leaderboard.
    address[] public allPlayers;

    /// @notice Game Lobby structure, 4 players max. "isFull" detects if last player entered and locks the struct for new
    struct gameLobby {
        address player1;
        address player2;
        address player3;
        address player4;
        address winner;
        uint8 playerCount;
        uint256 cost;
        uint256 livePool;
        bool isFull;
    }

    gameLobby[] public gameLobbies;

    /// @notice Seperate personal balance in contract. Used to pay for creating and joining games.
    mapping(address => uint256) balance;
    mapping(address => uint256) public wins;
    mapping(address => uint256) public losses;

    mapping(address => uint256) public tempWins;
    mapping(address => uint256) public tempLosses;

    constructor() {
        admin = msg.sender;
    }

    modifier isAdmin() {
        require(msg.sender == admin, "This function is for admin only");
        _;
    }

    function MyBalance() public view returns (uint256) {
        return (balance[msg.sender]);
    }

    function DepositFunds() public payable {
        require(msg.value > 0, "There is no point in depositing null ammount");
        balance[msg.sender] += msg.value;
        allPlayers.push(msg.sender);
        numberOfPlayers++;
    }

    function WithdrawFunds() public {
        uint256 withdrawableBalance = balance[msg.sender];
        balance[msg.sender] = 0;
        payable(msg.sender).transfer(withdrawableBalance);
    }

    /// @notice Seperate withdraw function for admins. Each game will transfer specified % to DevWallet.
    function WithdrawFundsAdmin() public isAdmin {
        uint256 withdrawableBalance = devWallet;
        devWallet = 0;
        payable(msg.sender).transfer(withdrawableBalance);
    }

    /// @notice Creates new game with specified cost and player count. Uses funds from Balance.
    function CreateLobby(uint8 _playerCount, uint256 _cost) public {
        require(
            balance[msg.sender] >= _cost * Eth,
            "You don't have enough funds deposited"
        );
        require(
            _playerCount > 1 && _playerCount <= 4,
            "You can only have 2, 3 or 4 players"
        );
        gameLobby memory newLobby = gameLobby(
            msg.sender,
            nullAddress,
            nullAddress,
            nullAddress,
            nullAddress,
            _playerCount,
            _cost,
            _cost * Eth,
            false
        );
        gameLobbies.push(newLobby);
        balance[msg.sender] -= _cost * Eth;
        emit NewGame(msg.sender, _playerCount, _cost);
    }

    /// @notice Checks if last slot of player is taken and joins the game.Uses funds from Balance.
    function JoinLobby(uint256 _id) public {
        require(gameLobbies[_id].isFull == false, "The game is full");
        require(
            balance[msg.sender] >= gameLobbies[_id].cost * Eth,
            "You don't have enough funds deposited"
        );
        balance[msg.sender] -= gameLobbies[_id].cost * Eth;
        uint256 lobbyPlayerCount = gameLobbies[_id].playerCount;
        gameLobbies[_id].livePool += gameLobbies[_id].cost * Eth;

        if (lobbyPlayerCount == 4) {
            if (gameLobbies[_id].player3 != nullAddress) {
                gameLobbies[_id].player4 = msg.sender;
                gameLobbies[_id].isFull = true;
            } else if (gameLobbies[_id].player2 != nullAddress) {
                gameLobbies[_id].player3 = msg.sender;
            } else {
                gameLobbies[_id].player2 = msg.sender;
            }
        } else if (lobbyPlayerCount == 3) {
            if (gameLobbies[_id].player2 != nullAddress) {
                gameLobbies[_id].player3 = msg.sender;
                gameLobbies[_id].isFull = true;
            } else {
                gameLobbies[_id].player2 = msg.sender;
            }
        } else {
            gameLobbies[_id].player2 = msg.sender;
            gameLobbies[_id].isFull = true;
        }

        emit JoinedGame(msg.sender, _id);
    }

    /// @notice Distributes funds to specific balances in contract.
    function SendFundsToWinner(uint256 _id) internal {
        uint256 ToMonthlyPool = (gameLobbies[_id].livePool / 100) *
            monthlyPoolPct;
        uint256 ToDevWallet = (gameLobbies[_id].livePool / 100) * devWalletPct;
        gameLobbies[_id].livePool -= (ToMonthlyPool + ToDevWallet);
        balance[gameLobbies[_id].winner] += gameLobbies[_id].livePool;
        monthlyPool += ToMonthlyPool;
        devWallet += ToDevWallet;
        emit Winner(gameLobbies[_id].winner, gameLobbies[_id].livePool);
    }

    /// @notice After each game each user will have updated Wins/Losses count.
    function AddWinsAndLosses(uint256 _id) internal {
        if (gameLobbies[_id].player1 == gameLobbies[_id].winner) {
            tempWins[gameLobbies[_id].player1]++;
            wins[gameLobbies[_id].player1]++;
        } else {
            tempLosses[gameLobbies[_id].player1]++;
            losses[gameLobbies[_id].player1]++;
        }

        if (gameLobbies[_id].player2 == gameLobbies[_id].winner) {
            tempWins[gameLobbies[_id].player2]++;
            wins[gameLobbies[_id].player2]++;
        } else {
            tempLosses[gameLobbies[_id].player2]++;
            losses[gameLobbies[_id].player2]++;
        }

        if (gameLobbies[_id].player3 == gameLobbies[_id].winner) {
            tempWins[gameLobbies[_id].player3]++;
            wins[gameLobbies[_id].player3]++;
        } else {
            tempLosses[gameLobbies[_id].player3]++;
            losses[gameLobbies[_id].player2]++;
        }

        if (gameLobbies[_id].player4 == gameLobbies[_id].winner) {
            tempWins[gameLobbies[_id].player4]++;
            wins[gameLobbies[_id].player3]++;
        } else {
            tempLosses[gameLobbies[_id].player4]++;
            losses[gameLobbies[_id].player2]++;
        }
    }

    /// @notice Winner is picked manually.
    /// @dev Game should be added in front-end. Winner of that game should be transfered to this function.
    function PickWinner(uint256 _id, uint256 _number) public isAdmin {
        require(
            _number >= 1 && _number <= 4,
            "Winner can be 1st, 2nd, 3rd or 4th player"
        );
        require(
            gameLobbies[_id].winner == nullAddress,
            "Winner is already picked"
        );
        require(gameLobbies[_id].isFull, "Lobby is not full");
        require(
            _number <= gameLobbies[_id].playerCount,
            "Number is higher than the playerCount"
        );

        if (_number == 4) {
            gameLobbies[_id].winner = gameLobbies[_id].player4;
        } else if (_number == 3) {
            gameLobbies[_id].winner = gameLobbies[_id].player3;
        } else if (_number == 2) {
            gameLobbies[_id].winner = gameLobbies[_id].player2;
        } else {
            gameLobbies[_id].winner = gameLobbies[_id].player1;
        }

        AddWinsAndLosses(_id);
        SendFundsToWinner(_id);
    }
}
