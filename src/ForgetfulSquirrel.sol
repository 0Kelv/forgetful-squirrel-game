// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**
 * @title ForgetfulSquirrel: A simple blockchain game of a hungry but unfortunately also quite forgetful cute squirrel.
 * @notice This contract implements a simple game, where players help a squirrel to find  Z <= N**2 nuts the squirrel has buried on a N**2 cells sized playground.
 * During a game round the player has Z guesses to find all nuts. The more nuts found and the smaller the ratio Z / N**2, the higher the score per found nut.
 * @dev The generation of pseudo-random booleans (used for placing nuts on the playground) utilizes block-related variables such as block timestamp and block number.
 * It's better to use Chainlink VRF for true randomness, which might be implemented in a later version of the game.
 * @notice version: 0.1.0
 */
contract ForgetfulSquirrel {   
  
    uint256 private constant PLAYGROUND_SIZE = 4;       
   
    enum CellStatus {
        EMPTY,
        NUT,
        FOUND
    }
    
    enum GameStatus {
        IDLE,
        INITIALIZED,
        STARTED,
        ENDED
    }

    struct Playground {
        uint256 buriedNutsCount;
        uint256 guessesLeft;
        uint256 correctGuesses;
        uint256 scoreFactor; 
        uint256 score;
        GameStatus status;
        mapping(uint256 => mapping(uint256 => CellStatus)) cells;
    }   
    
    //each player has its own playground.
    mapping(address => Playground) private players; 


    //create an array of pseudo-random booleans.
    function getRandomBooleanArray(uint256 size) public view returns (bool[] memory) {
        bool[] memory booleanArray = new bool[](size);
        for (uint256 i = 0; i < size; i++) {
            // Calculate a pseudo-random number using the block timestamp, the block number and the loop index i
            uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, i)));
            // Convert the random number to a boolean value by checking if the number is even (true) or odd (false)
            booleanArray[i] = (randomNumber % 2 == 0);
        }
        return booleanArray;
    }
   
   //bury nuts on the playground (max nuts: N**2)
    function buryNuts(Playground storage playground) internal {        
        bool[] memory booleanArray = getRandomBooleanArray(PLAYGROUND_SIZE ** 2);

        for (uint256 i = 0; i < PLAYGROUND_SIZE; i++) {
            for (uint256 j = 0; j < PLAYGROUND_SIZE; j++) {
                // Decide on a pseudo-random basis whether to bury a nut in the current cell or not
                if (booleanArray[i * j]) {
                    playground.cells[i][j] = CellStatus.NUT;
                    playground.buriedNutsCount++;
                }
                //TODO: implement proper fractional math here.
                playground.scoreFactor = PLAYGROUND_SIZE**2 / playground.buriedNutsCount;
            }
        }
    }    

    //initialize the game, i.e. bury nuts randomly on the playground.
    function initializeGame(Playground storage playground) internal {        
        buryNuts(playground);    
        //the player initially has as many guesses as nuts buried. Obviously, it gets harder with increasing playground size and fewer nuts buried, 
        //which will be reflected in the scoreFactor (see buryNuts function).   
        playground.guessesLeft = playground.buriedNutsCount;
        playground.status = GameStatus.INITIALIZED;
    }
    
    //start the game.
    function playGame() external {
        Playground storage playground = players[msg.sender];

        //Enums are initialized with their first value i.e. status.IDLE = 0 here.
        require(playground.status == GameStatus.IDLE, "The game is already running.");

        //initialize the game
        initializeGame(playground);
        require(playground.status == GameStatus.INITIALIZED, "The game has not been initialized correctly.");
        //start the game
        playground.status = GameStatus.STARTED;
    }

    function makeGuess(uint256 x, uint256 y) external returns (bool) {
        Playground storage playground = players[msg.sender];        
        require(playground.status == GameStatus.STARTED || playground.status == GameStatus.IDLE, "The game has not started yet. Please start the game first.");
        require(playground.guessesLeft > 0,"No more guesses left.");
        require(x < PLAYGROUND_SIZE && y < PLAYGROUND_SIZE, "Invalid coordinates. Required: x < 4 and y < 4.");
        playground.guessesLeft--;
        if (playground.guessesLeft == 0) {
            playground.status = GameStatus.ENDED;
        }
        if (playground.cells[x][y] == CellStatus.NUT) {
            playground.cells[x][y] = CellStatus.FOUND;
            playground.buriedNutsCount--;
            playground.correctGuesses++;            
            playground.score += playground.scoreFactor;               
            return true;
        }             
        return false;
    }
    
    function endGame() external {
        Playground storage playground = players[msg.sender];
        require(playground.status == GameStatus.STARTED || playground.status == GameStatus.IDLE, "The game has not even started yet.");
        playground.status = GameStatus.ENDED;
    }
    
    function getBuriedNutsCount() external view returns (uint256) {
        Playground storage playground = players[msg.sender];
        require(playground.status == GameStatus.STARTED, "The game has not started yet. Please start the game.");
        return playground.buriedNutsCount;
    }
    
    function getCurrentScore() external view returns (uint256) {
        Playground storage playground = players[msg.sender];
        require(playground.status == GameStatus.STARTED || playground.status == GameStatus.ENDED, "You haven't played the game yet. Please start the game.");
        return playground.score;
    }

    function getCorrectGuesses() external view returns (uint256) {
        Playground storage playground = players[msg.sender];
        require(playground.status == GameStatus.STARTED || playground.status == GameStatus.ENDED, "You haven't played the game yet. Please start the game.");
        return playground.correctGuesses;
    }
    
    function getGuessesLeft() external view returns (uint256) {
        Playground storage playground = players[msg.sender];
        require(playground.status == GameStatus.STARTED, "The game has not started yet. Please start the game.");
        return playground.guessesLeft;
    }
    
    function getGameStatus() external view returns (GameStatus) {
        Playground storage playground = players[msg.sender];
        return playground.status;
    }    
}