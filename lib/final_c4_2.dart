// client

/*import 'dart:io';
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
class GameState {
  List<List<int>> board = List.generate(ROWS, (_) => List.filled(COLUMNS, EMPTY));
  bool isMyTurn = false; // Server starts the game
  int myColor = YELLOW;
  int opponentColor = RED;
  bool gameOver = false;
  int? winner;

  GameState();

  void updateFromJson(Map<String, dynamic> json) {
    // Handle the board data properly
    List<dynamic> jsonBoard = json['board'];
    for (int i = 0; i < ROWS; i++) {
      List<dynamic> row = jsonBoard[i];
      for (int j = 0; j < COLUMNS; j++) {
        board[i][j] = row[j];
      }
    }

    isMyTurn = !json['isMyTurn']; // Invert server's turn for client perspective
    gameOver = json['gameOver'] ?? false;
    winner = json['winner'];
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
}

// Bloc state
class ConnectionState {
  Socket? theServer = null;
  bool listened = false;
  GameState gameState = GameState();

  ConnectionState(this.theServer, this.listened, this.gameState);
}

class ConnectionCubit extends Cubit<ConnectionState> {
  ConnectionCubit() : super(ConnectionState(null, false, GameState())) {
    if (state.theServer == null) {
      connect();
    }
  }

  update(Socket s) {
    emit(ConnectionState(s, state.listened, state.gameState));
  }

  updateListen() {
    emit(ConnectionState(state.theServer, true, state.gameState));
  }

  updateGameState(GameState gs) {
    emit(ConnectionState(state.theServer, state.listened, gs));
  }

  makeMove(int column) {
    final currentState = state;
    final gameState = currentState.gameState;

    if (gameState.isMyTurn && !gameState.gameOver && gameState.isValidMove(column)) {
      if (gameState.makeMove(column, YELLOW)) {
        //check for win condition
        if (gameState.gameOver && gameState.winner == YELLOW) {
          //play win sound effect
          AState(AudioPlayer()).playWinSoundEffect();
        }
        else{
          //play sound for regular move
          //print( "detected win");
          AState( AudioPlayer() ).play();
        }
        // Switch turns
        gameState.isMyTurn = false;

        // Send the move to server
        if (currentState.theServer != null) {
          Map<String, dynamic> message = {
            'type': 'move',
            'column': column,
          };
          currentState.theServer!.write(jsonEncode(message));
        }

        updateGameState(gameState);
      }
    }
  }

  receiveServerData(Map<String, dynamic> data) {
    final currentState = state;
    final gameState = currentState.gameState;

    if (data['type'] == 'game_init') {
      // Initialize game with server data
      if (data.containsKey('gameState')) {
        gameState.updateFromJson(data['gameState']);
      }
    } else if (data['type'] == 'move') {
      // Server made a move
      if (data.containsKey('gameState')) {
        gameState.updateFromJson(data['gameState']);
      }
    } else if (data['type'] == 'move_ack') {
      // Server acknowledged our move
      if (data.containsKey('gameState')) {
        gameState.updateFromJson(data['gameState']);
      }
    } else if (data['type'] == 'reset') {
      // Game has been reset
      if (data.containsKey('gameState')) {
        gameState.updateFromJson(data['gameState']);
      }
    }

    updateGameState(gameState);
  }

  Future<void> connect() async {
    await Future.delayed(const Duration(seconds: 2));
    try {
      final socket = await Socket.connect('localhost', 9203);
      print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      update(socket);
    } catch (e) {
      print('Error connecting to server: $e');
      // Try to connect again after a bit
      await Future.delayed(const Duration(seconds: 5));
      connect();
    }
  }
}

class SaidState {
  String said;

  SaidState(this.said);
}

class SaidCubit extends Cubit<SaidState> {
  SaidCubit() : super(SaidState("Connecting to Connect 4 server...\n"));

  void update(String s) {
    emit(SaidState("${state.said}\n$s"));
  }
}

void main() {
  runApp(Connect4Client());
}

class Connect4Client extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Connect 4 Client",
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BlocProvider<ConnectionCubit>(
        create: (context) => ConnectionCubit(),
        child: BlocBuilder<ConnectionCubit, ConnectionState>(
          builder: (context, state) => BlocProvider<SaidCubit>(
            create: (context) => SaidCubit(),
            child: BlocBuilder<SaidCubit, SaidState>(
              builder: (context, state) => Connect4ClientUI(),
            ),
          ),
        ),
      ),
    );
  }
}

class Connect4ClientUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ConnectionCubit cc = BlocProvider.of<ConnectionCubit>(context);
    ConnectionState cs = cc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(context);

    if (cs.theServer != null && !cs.listened) {
      listen(context);
      cc.updateListen();
    }
    //final screenHeight = MediaQuery.of(context).size.height;
   // final availableHeight = screenHeight -
      //  kToolbarHeight -  // AppBar height
      //  80;

    return Scaffold(
      appBar: AppBar(
        title: Text("Connect 4 - Player 2 (Yellow)"),
      ),
      body:
      Column(
        children: [
          // Game status
          Container(
            padding: EdgeInsets.all(8),//EdgeInsets.all(8)
            color: cs.gameState.gameOver
                ? Colors.grey[300]
                : (cs.gameState.isMyTurn ? Colors.green[100] : Colors.red[100]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cs.gameState.gameOver
                      ? (cs.gameState.winner == YELLOW
                      ? "You win!"
                      : (cs.gameState.winner == RED
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
            child: Container(
              //width:  MediaQuery.of(context).size.width * 0.4,
              //height: MediaQuery.of(context).size.height* 0.4,
              margin: EdgeInsets.all(10),
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
                          onPressed: cs.gameState.isValidMove(col) ? () => cc.makeMove(col) : null,
                        );
                      }),
                    ),
                  if (cs.gameState.gameOver || !cs.gameState.isMyTurn)
                    SizedBox(height: 48),  // 48 Placeholder for consistent layout

                  // Game board
                  Expanded(
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
                  /*LayoutBuilder(
                    builder: (context, constraints) {
                      // Ensure square cells and full board fits
                      double cellSize = (constraints.maxWidth - 16 - (COLUMNS - 1) * 5) / COLUMNS;
                      double gridHeight = cellSize * ROWS + (ROWS - 1) * 5;

                      return SizedBox(
                        height: gridHeight,
                        child: GridView.builder(
                          physics: NeverScrollableScrollPhysics(),
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
                            int displayRow = row; // or use ROWS - 1 - row if needed
                            int cell = cs.gameState.board[displayRow][col];

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.blue[800],
                                shape: BoxShape.circle,
                              ),
                              child: Container(
                                margin: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: cell == RED
                                      ? Colors.red
                                      : cell == YELLOW
                                      ? Colors.yellow
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  )*/
                  // Game board
                  /*SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: GridView.builder(
                      physics: NeverScrollableScrollPhysics(),
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
                        int displayRow = row; // use ROWS - 1 - row if needed for bottom-up logic

                        int cell = cs.gameState.board[displayRow][col];

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.blue[800],
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            margin: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: cell == RED
                                  ? Colors.red
                                  : cell == YELLOW
                                  ? Colors.yellow
                                  : Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                  ),*/


                ],
              ),
            ),
          ),

          // Connection status
          Container(
            padding: EdgeInsets.all(8),
            child: cs.theServer != null
                ? Text("Connected to the game")
                : Text("Trying to connect to the server..."),
          ),
        ],
      ),
    );
  }

  void listen(BuildContext bc) {
    ConnectionCubit cc = BlocProvider.of<ConnectionCubit>(bc);
    ConnectionState cs = cc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(bc);

    cs.theServer!.listen(
          (Uint8List data) async {
        final message = String.fromCharCodes(data);
        try {
          Map<String, dynamic> decodedMessage = jsonDecode(message);
          cc.receiveServerData(decodedMessage);

          if (decodedMessage['type'] == 'game_init') {
            sc.update("Connected to game server");
          } else if (decodedMessage['type'] == 'move') {
            sc.update("Your turn now");
          } else if (decodedMessage['type'] == 'reset') {
            sc.update("Game has been reset");
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
        sc.update("Server disconnected");
        // You might want to attempt reconnection here
      },
    );
  }
}*/
// client

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
class AState {
  AudioPlayer thep;
  AState(this.thep);
  void play() // put these in the project/assets folder
  {
    thep.play(AssetSource('connect4_sound_effect.mp4'));
  }
  void playWinSoundEffect(){
    thep.play(AssetSource('connect4_win_sound_effect.mp4'));
  }
}

// Game state
class GameState {
  List<List<int>> board = List.generate(ROWS, (_) => List.filled(COLUMNS, EMPTY));
  bool isMyTurn = false; // Server starts the game
  int myColor = YELLOW;
  int opponentColor = RED;
  bool gameOver = false;
  int? winner;

  // Added score tracking to match server
  int playerScore = 0;  // Client (YELLOW) score
  int opponentScore = 0;  // Server (RED) score

  GameState();

  void updateFromJson(Map<String, dynamic> json) {
    // Handle the board data properly
    List<dynamic> jsonBoard = json['board'];
    for (int i = 0; i < ROWS; i++) {
      List<dynamic> row = jsonBoard[i];
      for (int j = 0; j < COLUMNS; j++) {
        board[i][j] = row[j];
      }
    }

    isMyTurn = !json['isMyTurn']; // Invert server's turn for client perspective
    gameOver = json['gameOver'] ?? false;
    winner = json['winner'];

    // Update scores from server
    playerScore = json['opponentScore'] ?? 0;  // Our score is server's opponent score
    opponentScore = json['playerScore'] ?? 0;  // Opponent score is server's player score
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
      if (winner == YELLOW) {
        playerScore += 1;
      } else if (winner == RED) {
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
}

// Bloc state
class ConnectionState {
  Socket? theServer = null;
  bool listened = false;
  GameState gameState = GameState();

  ConnectionState(this.theServer, this.listened, this.gameState);
}

class ConnectionCubit extends Cubit<ConnectionState> {
  ConnectionCubit() : super(ConnectionState(null, false, GameState())) {
    if (state.theServer == null) {
      connect();
    }
  }

  update(Socket s) {
    emit(ConnectionState(s, state.listened, state.gameState));
  }

  updateListen() {
    emit(ConnectionState(state.theServer, true, state.gameState));
  }

  updateGameState(GameState gs, {int? lastRow, int? lastCol}) {
    emit(ConnectionState(state.theServer, state.listened, gs));
  }

  makeMove(int column) {
    final currentState = state;
    final gameState = currentState.gameState;

    if (gameState.isMyTurn && !gameState.gameOver && gameState.isValidMove(column)) {
      if (gameState.makeMove(column, YELLOW)) {
        // Find the row where the token landed
        int lastRow = -1;
        for (int r = 0; r < ROWS; r++) {
          if (gameState.board[r][column] == YELLOW) {
            lastRow = r;
            break;  // Find the topmost row with the token
          }
        }

        // Play sound effect based on game state
        if (gameState.gameOver && gameState.winner == YELLOW) {
          AState(AudioPlayer()).playWinSoundEffect();
        } else {
          AState(AudioPlayer()).play();
        }

        // Switch turns
        gameState.isMyTurn = false;

        // Send the move to server
        if (currentState.theServer != null) {
          Map<String, dynamic> message = {
            'type': 'move',
            'column': column,
          };
          currentState.theServer!.write(jsonEncode(message));
        }

        // Update with animation tracking
        updateGameState(gameState, lastRow: lastRow, lastCol: column);
      }
    }
  }

  receiveServerData(Map<String, dynamic> data) {
    final currentState = state;
    final gameState = currentState.gameState;

    if (data['type'] == 'game_init') {
      // Initialize game with server data
      if (data.containsKey('gameState')) {
        gameState.updateFromJson(data['gameState']);
      }
    } else if (data['type'] == 'move') {
      // Server made a move
      if (data.containsKey('gameState')) {
        gameState.updateFromJson(data['gameState']);
      }

      // Play sound effect if the server's move resulted in a win
      if (gameState.gameOver && gameState.winner == RED) {
        AState(AudioPlayer()).playWinSoundEffect();
      } else {
        AState(AudioPlayer()).play();
      }

    } else if (data['type'] == 'move_ack') {
      // Server acknowledged our move
      if (data.containsKey('gameState')) {
        gameState.updateFromJson(data['gameState']);
      }
    } else if (data['type'] == 'reset') {
      // Game has been reset
      if (data.containsKey('gameState')) {
        gameState.updateFromJson(data['gameState']);
      }
    }

    updateGameState(gameState);
  }

  Future<void> connect() async {
    await Future.delayed(const Duration(seconds: 2));
    try {
      final socket = await Socket.connect('localhost', 9203);
      print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      update(socket);
    } catch (e) {
      print('Error connecting to server: $e');
      // Try to connect again after a bit
      await Future.delayed(const Duration(seconds: 5));
      connect();
    }
  }
}

class SaidState {
  String said;

  SaidState(this.said);
}

class SaidCubit extends Cubit<SaidState> {
  SaidCubit() : super(SaidState("Connecting to Connect 4 server...\n"));

  void update(String s) {
    emit(SaidState("${state.said}\n$s"));
  }
}

void main() {
  runApp(Connect4Client());
}

class Connect4Client extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Connect 4 Client",
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BlocProvider<ConnectionCubit>(
        create: (context) => ConnectionCubit(),
        child: BlocBuilder<ConnectionCubit, ConnectionState>(
          builder: (context, state) => BlocProvider<SaidCubit>(
            create: (context) => SaidCubit(),
            child: BlocBuilder<SaidCubit, SaidState>(
              builder: (context, state) => Connect4ClientUI(),
            ),
          ),
        ),
      ),
    );
  }
}

/*class Connect4ClientUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ConnectionCubit cc = BlocProvider.of<ConnectionCubit>(context);
    ConnectionState cs = cc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(context);

    if (cs.theServer != null && !cs.listened) {
      listen(context);
      cc.updateListen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Connect 4 - Player 2 (Yellow)"),
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
                        color: Colors.yellow,
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
                        color: Colors.red,
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
                      ? (cs.gameState.winner == YELLOW
                      ? "You win!"
                      : (cs.gameState.winner == RED
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
                              splashColor: Colors.yellow[300],
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

                          // Get the token color
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
                              // Token
                              Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: tokenColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    if (cs.gameState.board[row][col] != EMPTY)
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        spreadRadius: 1,
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                  ],
                                ),
                              ),
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

          // Connection status
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                cs.theServer != null
                    ? const Text("Connected to the game")
                    : const Text("Trying to connect to the server..."),
                if (cs.gameState.gameOver)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Waiting for server to start a new game...",
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

    cs.theServer!.listen(
          (Uint8List data) async {
        final message = String.fromCharCodes(data);
        try {
          Map<String, dynamic> decodedMessage = jsonDecode(message);
          cc.receiveServerData(decodedMessage);

          if (decodedMessage['type'] == 'game_init') {
            sc.update("Connected to game server");
          } else if (decodedMessage['type'] == 'move') {
            sc.update("Your turn now");
          } else if (decodedMessage['type'] == 'reset') {
            sc.update("Game has been reset");
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
        sc.update("Server disconnected");
        // Attempt reconnection after a delay
        Future.delayed(const Duration(seconds: 5), () {
          cc.connect();
        });
      },
    );
  }
}*/
class Connect4ClientUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ConnectionCubit cc = BlocProvider.of<ConnectionCubit>(context);
    ConnectionState cs = cc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(context);

    if (cs.theServer != null && !cs.listened) {
      listen(context);
      cc.updateListen();
    }
    //final screenHeight = MediaQuery.of(context).size.height;
    // final availableHeight = screenHeight -
    //  kToolbarHeight -  // AppBar height
    //  80;

    return Scaffold(
      appBar: AppBar(
        title: Text("Connect 4 - Player 2 (Yellow)"),
      ),
      body:
      Column(
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
                        color: Colors.yellow,
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
                        color: Colors.red,
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
            padding: EdgeInsets.all(8),//EdgeInsets.all(8)
            color: cs.gameState.gameOver
                ? Colors.grey[300]
                : (cs.gameState.isMyTurn ? Colors.green[100] : Colors.red[100]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cs.gameState.gameOver
                      ? (cs.gameState.winner == YELLOW
                      ? "You win!"
                      : (cs.gameState.winner == RED
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
            child: Container(
              //width:  MediaQuery.of(context).size.width * 0.4,
              //height: MediaQuery.of(context).size.height* 0.4,
              margin: EdgeInsets.all(10),
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
                          onPressed: cs.gameState.isValidMove(col) ? () => cc.makeMove(col) : null,
                        );
                      }),
                    ),
                  if (cs.gameState.gameOver || !cs.gameState.isMyTurn)
                    SizedBox(height: 48),  // 48 Placeholder for consistent layout

                  // Game board
                  Expanded(
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
                  /*LayoutBuilder(
                    builder: (context, constraints) {
                      // Ensure square cells and full board fits
                      double cellSize = (constraints.maxWidth - 16 - (COLUMNS - 1) * 5) / COLUMNS;
                      double gridHeight = cellSize * ROWS + (ROWS - 1) * 5;

                      return SizedBox(
                        height: gridHeight,
                        child: GridView.builder(
                          physics: NeverScrollableScrollPhysics(),
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
                            int displayRow = row; // or use ROWS - 1 - row if needed
                            int cell = cs.gameState.board[displayRow][col];

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.blue[800],
                                shape: BoxShape.circle,
                              ),
                              child: Container(
                                margin: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: cell == RED
                                      ? Colors.red
                                      : cell == YELLOW
                                      ? Colors.yellow
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  )*/
                  // Game board
                  /*SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: GridView.builder(
                      physics: NeverScrollableScrollPhysics(),
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
                        int displayRow = row; // use ROWS - 1 - row if needed for bottom-up logic

                        int cell = cs.gameState.board[displayRow][col];

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.blue[800],
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            margin: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: cell == RED
                                  ? Colors.red
                                  : cell == YELLOW
                                  ? Colors.yellow
                                  : Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                  ),*/


                ],
              ),
            ),
          ),

          // Connection status
          Container(
            padding: EdgeInsets.all(8),
            child: cs.theServer != null
                ? Text("Connected to the game")
                : Text("Trying to connect to the server..."),
          ),
        ],
      ),
    );
  }

  void listen(BuildContext bc) {
    ConnectionCubit cc = BlocProvider.of<ConnectionCubit>(bc);
    ConnectionState cs = cc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(bc);

    cs.theServer!.listen(
          (Uint8List data) async {
        final message = String.fromCharCodes(data);
        try {
          Map<String, dynamic> decodedMessage = jsonDecode(message);
          cc.receiveServerData(decodedMessage);

          if (decodedMessage['type'] == 'game_init') {
            sc.update("Connected to game server");
          } else if (decodedMessage['type'] == 'move') {
            sc.update("Your turn now");
          } else if (decodedMessage['type'] == 'reset') {
            sc.update("Game has been reset");
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
        sc.update("Server disconnected");
        // You might want to attempt reconnection here
      },
    );
  }
}