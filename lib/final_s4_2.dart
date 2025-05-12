// server

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import 'package:audioplayers/audioplayers.dart';

const int COLUMNS = 7;  // Standard Connect 4 has 7 columns
const int ROWS = 6;     // and 6 rows

// Player colors
const int EMPTY = 0;
const int RED = 1;      // Player 1 (Server)
const int YELLOW = 2;   // Player 2 (Client)

//vv-- for sound effect --vv
class AState
{
  AudioPlayer thep;
  AState( this.thep);
  void play() // put these in the project/assets folder
  {
    thep.play(AssetSource('connect4_sound_effect.mp4'));
  }
  void playWinSoundEffect(){
    thep.play( AssetSource('connect4_win_sound_effect.mp4'));
  }
}


// Game state
// Game state
class GameState {
  List<List<int>> board = List.generate(ROWS, (_) => List.filled(COLUMNS, EMPTY));
  bool isMyTurn = true; // Server starts the game
  int myColor = RED;
  int opponentColor = YELLOW;
  bool gameOver = false;
  int? winner;

  // Added score tracking
  int playerScore = 0;  // Server (RED) score
  int opponentScore = 0;  // Client (YELLOW) score

  GameState();

  // Convert to json
  Map<String, dynamic> toJson() {
    return {
      'board': board,
      'isMyTurn': isMyTurn,
      'gameOver': gameOver,
      'winner': winner,
      'playerScore': playerScore,
      'opponentScore': opponentScore,
    };
  }

  // Check if a move is valid
  bool isValidMove(int column) {
    if (column < 0 || column >= COLUMNS) return false;
    return board[0][column] == EMPTY; // Check if the top cell in the column is empty
  }

  // Add a piece to the specified column
  bool makeMove(int column, int playerColor) {
    if (!isValidMove(column)) return false;

    // Find the lowest empty cell in the column
    int row = ROWS - 1;
    while (row >= 0 && board[row][column] != EMPTY) {
      row--;
    }

    if (row >= 0) {
      board[row][column] = playerColor;
      checkGameOver(row, column, playerColor);
      return true;
    }
    return false;
  }

  // Check if the game is over after a move
  void checkGameOver(int lastRow, int lastColumn, int playerColor) {
    // Check horizontal
    if (checkDirection(lastRow, lastColumn, 0, 1, playerColor) ||
        // Check vertical
        checkDirection(lastRow, lastColumn, 1, 0, playerColor) ||
        // Check diagonal /
        checkDirection(lastRow, lastColumn, -1, 1, playerColor) ||
        // Check diagonal \
        checkDirection(lastRow, lastColumn, 1, 1, playerColor)) {
      gameOver = true;
      winner = playerColor;

      // Update scores when game ends with a winner
      if (winner == RED) {
        playerScore += 1;
      } else if (winner == YELLOW) {
        opponentScore += 1;
      }

      return;
    }

    // Check for draw (board is full)
    bool isFull = true;
    for (int col = 0; col < COLUMNS; col++) {
      if (board[0][col] == EMPTY) {
        isFull = false;
        break;
      }
    }

    if (isFull) {
      gameOver = true;
      winner = null; // Draw
    }
  }

  // Check if there are 4 in a row in a specific direction
  bool checkDirection(int row, int col, int rowDir, int colDir, int playerColor) {
    int count = 1; // Start with 1 (the piece we just placed)

    // Check in one direction
    int r = row + rowDir;
    int c = col + colDir;
    while (r >= 0 && r < ROWS && c >= 0 && c < COLUMNS && board[r][c] == playerColor) {
      count++;
      r += rowDir;
      c += colDir;
    }

    // Check in the opposite direction
    r = row - rowDir;
    c = col - colDir;
    while (r >= 0 && r < ROWS && c >= 0 && c < COLUMNS && board[r][c] == playerColor) {
      count++;
      r -= rowDir;
      c -= colDir;
    }

    return count >= 4;
  }

  // Reset just the board but keep scores
  void resetBoard() {
    board = List.generate(ROWS, (_) => List.filled(COLUMNS, EMPTY));
    isMyTurn = true;
    gameOver = false;
    winner = null;
  }
}
/*class GameState{
  List<List<int>> board = List.generate(ROWS, (_) => List.filled(COLUMNS, EMPTY));
  bool isMyTurn = true; // Server starts the game
  int myColor = RED;
  int opponentColor = YELLOW;
  bool gameOver = false;
  int? winner;

  GameState();

  // Convert to json
  Map<String, dynamic> toJson() {
    return {
      'board': board,
      'isMyTurn': isMyTurn,
      'gameOver': gameOver,
      'winner': winner,
    };
  }

  // Check if a move is valid
  bool isValidMove(int column) {
    if (column < 0 || column >= COLUMNS) return false;
    return board[0][column] == EMPTY; // Check if the top cell in the column is empty
  }

  // Add a piece to the specified column
  bool makeMove(int column, int playerColor) {
    if (!isValidMove(column)) return false;

    // Find the lowest empty cell in the column
    int row = ROWS - 1;
    while (row >= 0 && board[row][column] != EMPTY) {
      row--;
    }

    if (row >= 0) {
      board[row][column] = playerColor;
      checkGameOver(row, column, playerColor);
      return true;
    }
    return false;
  }

  // Check if the game is over after a move
  void checkGameOver(int lastRow, int lastColumn, int playerColor) {
    // Check horizontal
    if (checkDirection(lastRow, lastColumn, 0, 1, playerColor) ||
        // Check vertical
        checkDirection(lastRow, lastColumn, 1, 0, playerColor) ||
        // Check diagonal /
        checkDirection(lastRow, lastColumn, -1, 1, playerColor) ||
        // Check diagonal \
        checkDirection(lastRow, lastColumn, 1, 1, playerColor)) {
      gameOver = true;
      winner = playerColor;
      //if( playerColor == RED ){
        //play win sound effect
        //AState( AudioPlayer() ).playWinSoundEffect();
      //}
      return;
    }

    // Check for draw (board is full)
    bool isFull = true;
    for (int col = 0; col < COLUMNS; col++) {
      if (board[0][col] == EMPTY) {
        isFull = false;
        break;
      }
    }

    if (isFull) {
      gameOver = true;
      winner = null; // Draw
    }
  }

  // Check if there are 4 in a row in a specific direction
  bool checkDirection(int row, int col, int rowDir, int colDir, int playerColor) {
    int count = 1; // Start with 1 (the piece we just placed)

    // Check in one direction
    int r = row + rowDir;
    int c = col + colDir;
    while (r >= 0 && r < ROWS && c >= 0 && c < COLUMNS && board[r][c] == playerColor) {
      count++;
      r += rowDir;
      c += colDir;
    }

    // Check in the opposite direction
    r = row - rowDir;
    c = col - colDir;
    while (r >= 0 && r < ROWS && c >= 0 && c < COLUMNS && board[r][c] == playerColor) {
      count++;
      r -= rowDir;
      c -= colDir;
    }

    return count >= 4;
  }
}*/

// Bloc state
class ConnectionState {
  bool listening = false;
  Socket? theClient = null;
  bool listened = false;
  GameState gameState = GameState();

  ConnectionState(this.listening, this.theClient, this.listened, this.gameState);
}

class ConnectionCubit extends Cubit<ConnectionState> {
  ConnectionCubit() : super(ConnectionState(false, null, false, GameState())) {
    if (state.theClient == null) {
      connect();
    }
  }

  update(bool b, Socket s) {
    emit(ConnectionState(b, s, state.listened, state.gameState));
  }

  updateListen() {
    emit(ConnectionState(true, state.theClient, true, state.gameState));
  }

  updateGameState(GameState gs, {int? lastRow, int? lastCol}) {
    emit(ConnectionState(
      state.listening,
      state.theClient,
      state.listened,
      gs,
    ) );
  }

  makeMove(int column) {
    final currentState = state;
    final gameState = currentState.gameState;

    if (gameState.isMyTurn && !gameState.gameOver && gameState.isValidMove(column)) {
      if (gameState.makeMove(column, RED)) {
        // Find the row where the token landed
        int lastRow = -1;
        for (int r = 0; r < ROWS; r++) {
          if (gameState.board[r][column] == RED) {
            lastRow = r;
            break;  // Find the topmost row with the token
          }
        }

        // Play sound effect based on game state
        if (gameState.gameOver && gameState.winner == RED) {
          AState(AudioPlayer()).playWinSoundEffect();
        } else {
          AState(AudioPlayer()).play();
        }

        // Switch turns
        gameState.isMyTurn = false;

        // Send the move to client
        if (currentState.theClient != null) {
          Map<String, dynamic> message = {
            'type': 'move',
            'column': column,
            'gameState': gameState.toJson(),
          };
          currentState.theClient!.write(jsonEncode(message));
        }

        // Update with animation tracking
        updateGameState(gameState, lastRow: lastRow, lastCol: column);
      }
    }
  }

  receiveClientMove(Map<String, dynamic> data) {
    final currentState = state;
    final gameState = currentState.gameState;

    if (data.containsKey('column')) {
      int column = data['column'];

      // Update the board with the client's move
      if (gameState.makeMove(column, YELLOW)) {
        // Find the row where the token landed
        int lastRow = -1;
        for (int r = 0; r < ROWS; r++) {
          if (gameState.board[r][column] == YELLOW) {
            lastRow = r;
            break;  // Find the topmost row with the token
          }
        }

        // Play sound effect
        if (gameState.gameOver && gameState.winner == YELLOW) {
          AState(AudioPlayer()).playWinSoundEffect();
        } else {
          AState(AudioPlayer()).play();
        }

        // Switch turns back to server
        gameState.isMyTurn = true;

        // Update with animation tracking
        updateGameState(gameState, lastRow: lastRow, lastCol: column);

        // Send acknowledgment to the client
        if (currentState.theClient != null) {
          Map<String, dynamic> ackMessage = {
            'type': 'move_ack',
            'gameState': gameState.toJson(),
          };
          currentState.theClient!.write(jsonEncode(ackMessage));
        }
      }
    }
  }

  resetGame() {
    final currentState = state;
    final gameState = currentState.gameState;

    // Save the scores before reset
    int playerScore = gameState.playerScore;
    int opponentScore = gameState.opponentScore;

    // Create a new game state but retain scores
    gameState.resetBoard();

    // Send reset message to client
    if (currentState.theClient != null) {
      Map<String, dynamic> message = {
        'type': 'reset',
        'gameState': gameState.toJson(),
      };
      currentState.theClient!.write(jsonEncode(message));
    }

    emit(ConnectionState(state.listening, state.theClient, state.listened, gameState));
  }

  Future<void> connect() async {
    await Future.delayed(const Duration(seconds: 2));
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, 9203);
    print("Connect 4 server started and waiting for a player to join...");

    server.listen((client) {
      emit(ConnectionState(true, client, state.listened, state.gameState));

      // Send initial state of the game
      if (client != null) {
        Map<String, dynamic> message = {
          'type': 'game_init',
          'gameState': state.gameState.toJson(),
        };
        client.write(jsonEncode(message));
      }
    });

    emit(ConnectionState(true, null, false, state.gameState));
  }
}
/*class ConnectionCubit extends Cubit<ConnectionState> {
  ConnectionCubit() : super(ConnectionState(false, null, false, GameState())) {
    if (state.theClient == null) {
      connect();
    }
  }

  update(bool b, Socket s) {
    emit(ConnectionState(b, s, state.listened, state.gameState));
  }

  updateListen() {
    emit(ConnectionState(true, state.theClient, true, state.gameState));
  }

  updateGameState(GameState gs) {
    emit(ConnectionState(state.listening, state.theClient, state.listened, gs));
  }

  makeMove(int column) {
    final currentState = state;
    final gameState = currentState.gameState;

    if (gameState.isMyTurn && !gameState.gameOver && gameState.isValidMove(column)) {
      if (gameState.makeMove(column, RED)) {
        int lastRow = gameState.board.lastIndexWhere((r) => r[column] == RED);
        //check for win condition
        if (gameState.gameOver && gameState.winner == RED) {
          //play win sound effect
          AState(AudioPlayer()).playWinSoundEffect();
        }
        else{
          //play sound for regular move
          //print( "detected win");
          AState( AudioPlayer() ).play();
        }
        //print( "over here" );
        // Switch turns
        gameState.isMyTurn = false;

        // Send the move to client
        if (currentState.theClient != null) {
          Map<String, dynamic> message = {
            'type': 'move',
            'column': column,
            'gameState': gameState.toJson(),
          };
          currentState.theClient!.write(jsonEncode(message));
        }

        updateGameState(gameState);
        //updateGameState(gameState, lastRow: lastRow, lastCol: column);
      }
    }
  }

  receiveClientMove(Map<String, dynamic> data) {
    final currentState = state;
    final gameState = currentState.gameState;

    if (data.containsKey('column')) {
      int column = data['column'];

      // Update the board with the client's move
      if (gameState.makeMove(column, YELLOW)) {
        // Switch turns back to server
        gameState.isMyTurn = true;

        updateGameState(gameState);

        // Send acknowledgment to the client
        if (currentState.theClient != null) {
          Map<String, dynamic> ackMessage = {
            'type': 'move_ack',
            'gameState': gameState.toJson(),
          };
          currentState.theClient!.write(jsonEncode(ackMessage));
        }
      }
    }
  }

  resetGame() {
    final currentState = state;
    final newGameState = GameState();

    // Send reset message to client
    if (currentState.theClient != null) {
      Map<String, dynamic> message = {
        'type': 'reset',
        'gameState': newGameState.toJson(),
      };
      currentState.theClient!.write(jsonEncode(message));
    }

    emit(ConnectionState(state.listening, state.theClient, state.listened, newGameState));
  }

  Future<void> connect() async {
    await Future.delayed(const Duration(seconds: 2));
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, 9203);
    print("Connect 4 server started and waiting for a player to join...");

    server.listen((client) {
      emit(ConnectionState(true, client, state.listened, state.gameState));

      // Send initial state of the game
      if (client != null) {
        Map<String, dynamic> message = {
          'type': 'game_init',
          'gameState': state.gameState.toJson(),
        };
        client.write(jsonEncode(message));
      }
    });

    emit(ConnectionState(true, null, false, state.gameState));
  }
}*/

class SaidState {
  String said;

  SaidState(this.said);
}

class SaidCubit extends Cubit<SaidState> {
  SaidCubit() : super(SaidState("Connect 4 server started...\n"));

  void update(String s) {
    emit(SaidState("${state.said}\n$s"));
  }
}

void main() {
  runApp(Connect4Server());
}

class Connect4Server extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: "Connect 4 Server",
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BlocProvider<ConnectionCubit>(
        create: (context) => ConnectionCubit(),
        child: BlocBuilder<ConnectionCubit, ConnectionState>(
          builder: (context, state) => BlocProvider<SaidCubit>(
            create: (context) => SaidCubit(),
            child: BlocBuilder<SaidCubit, SaidState>(
              builder: (context, state) => Connect4ServerUI(),
            ),
          ),
        ),
      ),
    );
  }
}
/*class Connect4ServerUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ConnectionCubit cc = BlocProvider.of<ConnectionCubit>(context);
    ConnectionState cs = cc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(context);

    if (cs.theClient != null && !cs.listened) {
      listen(context);
      cc.updateListen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Connect 4 - Player 1 (Red)"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: !cs.gameState.gameOver ? null : () => cc.resetGame(),
            tooltip: "Reset Game",
          ),
        ],
      ),
      body: Column(
        children: [
          // Score Display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.blue[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "You: ${cs.gameState.playerScore}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "Opponent: ${cs.gameState.opponentScore}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Game status
          Container(
            padding: const EdgeInsets.all(8),
            color: cs.gameState.gameOver
                ? Colors.grey[300]
                : (cs.gameState.isMyTurn ? Colors.green[100] : Colors.red[100]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cs.gameState.gameOver
                      ? (cs.gameState.winner == RED
                      ? "You win!"
                      : (cs.gameState.winner == YELLOW
                      ? "Opponent wins!"
                      : "Draw!"))
                      : (cs.gameState.isMyTurn
                      ? "Your Turn"
                      : "Opponent's Turn"),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),

          // Connect 4 board
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Column selector buttons
                  if (!cs.gameState.gameOver && cs.gameState.isMyTurn)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(COLUMNS, (col) {
                        bool isValid = cs.gameState.isValidMove(col);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_downward),
                              color: isValid ? Colors.white : Colors.white.withOpacity(0.3),
                              onPressed: isValid ? () => cc.makeMove(col) : null,
                              splashColor: Colors.red[300],
                            ),
                          ),
                        );
                      }),
                    ),
                  if (cs.gameState.gameOver || !cs.gameState.isMyTurn)
                    const SizedBox(height: 48),  // Placeholder for consistent layout

                  // Game board
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(), // Prevent scrolling
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: COLUMNS,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 5,
                        ),
                        itemCount: ROWS * COLUMNS,
                        itemBuilder: (context, index) {
                          int row = index ~/ COLUMNS;
                          int col = index % COLUMNS;

                          // Get the token color and calculate if this is the last placed token
                          Color tokenColor;

                          if (cs.gameState.board[row][col] == RED) {
                            tokenColor = Colors.red;
                          } else if (cs.gameState.board[row][col] == YELLOW) {
                            tokenColor = Colors.yellow;
                          } else {
                            tokenColor = Colors.white;
                          }

                          // Cell with hole effect
                          return Stack(
                            children: [
                              // Background
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue[800],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.blue[900]!,
                                    width: 2,
                                  ),
                                ),
                              ),

                              // Token (with animation if it's the last placed token)
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status and reset text
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                cs.theClient != null
                    ? const Text("Player 2 connected")
                    : const Text("Waiting for Player 2 to connect..."),
                if (cs.gameState.gameOver)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Tap the reset button in the top right to play again",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void listen(BuildContext bc) {
    ConnectionCubit cc = BlocProvider.of<ConnectionCubit>(bc);
    ConnectionState cs = cc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(bc);

    cs.theClient!.listen(
          (Uint8List data) async {
        final message = String.fromCharCodes(data);
        try {
          Map<String, dynamic> decodedMessage = jsonDecode(message);
          if (decodedMessage['type'] == 'move') {
            cc.receiveClientMove(decodedMessage);
            sc.update("Received move from Player 2");
          }
        } catch (e) {
          sc.update("Error processing message: $e");
        }
      },
      onError: (error) {
        print(error);
        sc.update("Connection error: $error");
      },
      onDone: () {
        sc.update("Player 2 disconnected");
      },
    );
  }
}*/

class Connect4ServerUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ConnectionCubit cc = BlocProvider.of<ConnectionCubit>(context);
    ConnectionState cs = cc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(context);
    //AState ac = AState(AudioPlayer());

    if (cs.theClient != null && !cs.listened) {
      listen(context);
      cc.updateListen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Connect 4 - Player 1 (Red)"),
        /*actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: !cs.gameState.gameOver ? null : () => cc.resetGame(),
            tooltip: "Reset Game",
          ),
        ],*/
      ),
      body: Column(
        children: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => {
              print( "request to reset game"),
              cc.resetGame()
            },
            tooltip: "Reset Game",
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.blue[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "You: ${cs.gameState.playerScore}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "Opponent: ${cs.gameState.opponentScore}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Game status
          Container(
            padding: EdgeInsets.all(8), //EdgeInsets.all(8)
            color: cs.gameState.gameOver
                ? Colors.grey[300]
                : (cs.gameState.isMyTurn ? Colors.green[100] : Colors.red[100]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cs.gameState.gameOver
                      ? (cs.gameState.winner == RED
                      ? "You win!"
                      : (cs.gameState.winner == YELLOW
                      ? "Opponent wins!"
                      : "Draw!"))
                      : (cs.gameState.isMyTurn
                      ? "Your Turn"
                      : "Opponent's Turn"),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),

          // Connect 4 board
          Expanded(
          //Container(
            child: Container(
              //width:  MediaQuery.of(context).size.width * 0.4,
              //height: MediaQuery.of(context).size.height* 0.4,
              //margin: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Column(
                children: [
                  // Column selector buttons
                  if (!cs.gameState.gameOver && cs.gameState.isMyTurn)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(COLUMNS, (col) {
                        return IconButton(
                          icon: Icon(Icons.arrow_downward),
                          color: Colors.white,
                          onPressed:
                              cs.gameState.isValidMove(col) ? () => {
                                  cc.makeMove(col),
                                  //ac.play()
                              }
                                  : null

                        );
                      }),
                    ),
                  if (cs.gameState.gameOver || !cs.gameState.isMyTurn)
                    SizedBox(height: 48),  // 48 Placeholder for consistent layout

                  // Game board
                  Expanded(
                  //Container(
                    child: GridView.builder(
                      padding: EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: COLUMNS,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                      ),
                      itemCount: ROWS * COLUMNS,
                      itemBuilder: (context, index) {
                        int row = index ~/ COLUMNS;
                        int col = index % COLUMNS;

                        // We need to invert the rows since Connect 4 has the origin at the bottom
                        int displayRow = /*ROWS - 1 -*/ row;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.blue[800],
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            margin: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: cs.gameState.board[displayRow][col] == RED
                                  ? Colors.red
                                  : cs.gameState.board[displayRow][col] == YELLOW
                                  ? Colors.yellow
                                  : Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status text
          Container(
            padding: EdgeInsets.all(8),
            child: cs.theClient != null
                ? Text("Player 2 connected")
                : Text("Waiting for Player 2 to connect..."),
          ),
        ],
      ),
    );
  }

  void listen(BuildContext bc) {
    ConnectionCubit cc = BlocProvider.of<ConnectionCubit>(bc);
    ConnectionState cs = cc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(bc);

    cs.theClient!.listen(
          (Uint8List data) async {
        final message = String.fromCharCodes(data);
        try {
          Map<String, dynamic> decodedMessage = jsonDecode(message);
          if (decodedMessage['type'] == 'move') {
            cc.receiveClientMove(decodedMessage);
            sc.update("Received move from Player 2");
          }
        } catch (e) {
          sc.update("Error processing message: $e");
        }
      },
      onError: (error) {
        print(error);
        sc.update("Connection error: $error");
      },
      onDone: () {
        sc.update("Player 2 disconnected");
      },
    );
  }
}