//client
//goes second
//plays YELLOW
//heidi- final project

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

const int COLUMNS = 7;  //connect4 board has 7 cols
const int ROWS = 6;     //and 6 rows

const int EMPTY = 0;
const int RED = 1;      //server color
const int YELLOW = 2;   //client color (us)

//vv-- for sound effect --vv
class AState {
  AudioPlayer thep;
  AState(this.thep);
  void play() // put these in the project/assets folder
  {
    //this is the sound effect when a token is "dropped" into a column
    thep.play(AssetSource('connect4_sound_effect.mp4'));
  }
  void playWinSoundEffect(){
    //this is the sound effect when a player wins
    thep.play(AssetSource('connect4_win_sound_effect.mp4'));
  }
  void playBombSoundEffect() {
    thep.play(AssetSource('bomb_sound_effect.mp4'));
  }
}

//keeps track of the current game
//and stores data like the board state, player scores, etc
//has functions that check if a move is valid, etc
class GameState {
  List<List<int>> board = List.generate(ROWS, (_) => List.filled(COLUMNS, EMPTY));
  bool isMyTurn = false; //server goes first
  int myColor = YELLOW;
  int opponentColor = RED;
  bool gameOver = false;
  int? winner;
  bool bomb = false;

  //vv-- keep track of scores --vv
  int playerScore = 0;  //client (us)
  int opponentScore = 0;  //server

  GameState();

  //we only keep track of player scores
  //and the state of the connect 4 board
  //we don't want to store variables that say whether we've connected to the client
  //bc we'll have to reconnect each time our server anyways
  void fromJson(Map<String, dynamic> json) {
    board = List<List<int>>.from(
      json['board'].map<List<int>>((row) => List<int>.from(row)),
    );
    isMyTurn = json['isMyTurn'] as bool;
    gameOver = json['gameOver'] as bool;
    winner = json['winner'];
    playerScore = json['playerScore'] ?? 0;
    opponentScore = json['opponentScore'] ?? 0;
  }

  //convert game state to json (serialize)
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
  void updateFromJson(Map<String, dynamic> json) {
    // Handle the board data properly
    List<dynamic> jsonBoard = json['board'];
    for (int i = 0; i < ROWS; i++) {
      List<dynamic> row = jsonBoard[i];
      for (int j = 0; j < COLUMNS; j++) {
        board[i][j] = row[j];
      }
    }

    isMyTurn = !json['isMyTurn']; //invert
    gameOver = json['gameOver'] ?? false;
    winner = json['winner'];
    bomb = false;

    // Update scores from server
    playerScore = json['opponentScore'] ?? 0;  //OUR score is server's opponent score
    opponentScore = json['playerScore'] ?? 0;  //OPPONENT score is server's player score
  }

  //check if a move is valid
  //(a move is only valid if there are still empty slots in the chosen column)
  bool isValidMove(int column) {
    if (column < 0 || column >= COLUMNS) return false;
    return board[0][column] == EMPTY;
  }

  //drop token into specified column
  bool makeMove(int column, int playerColor) {
    if (!isValidMove(column)) return false;

    // Generate bomb with 25% probability
    bomb = Random().nextDouble() < 0.1;

    int row = ROWS - 1;

    if (bomb) {
      // Clear out the whole column
      for (int k = ROWS-1; k >= 0; k--) {
        if (board[k][column] == EMPTY) break;
        board[k][column] = EMPTY;
      }
      row = ROWS - 1;
    } else {
      // Find the lowest empty cell in the column
      while (row >= 0 && board[row][column] != EMPTY) {
        row--;
      }
    }

    if (row >= 0) {
      board[row][column] = playerColor;
      checkGameOver(row, column, playerColor);
      return true;
    }
    return false;
  }


  //check if game over after a move
  void checkGameOver(int lastRow, int lastColumn, int playerColor) {
    //horizontal
    if (checkDirection(lastRow, lastColumn, 0, 1, playerColor) ||
        //vertical
        checkDirection(lastRow, lastColumn, 1, 0, playerColor) ||
        //diagonal /
        checkDirection(lastRow, lastColumn, -1, 1, playerColor) ||
        //diagonal \
        checkDirection(lastRow, lastColumn, 1, 1, playerColor)) {
      gameOver = true;
      winner = playerColor;

      //update score if game over
      if (winner == YELLOW) {
        playerScore += 1;
      } else if (winner == RED) {
        opponentScore += 1;
      }

      return;
    }

    //check for draw (board full)
    bool isFull = true;
    for (int col = 0; col < COLUMNS; col++) {
      if (board[0][col] == EMPTY) {
        isFull = false;
        break;
      }
    }

    if (isFull) {
      gameOver = true;
      winner = null; //set draw
    }
  }

  //after dropping token,
  //check if there are 4 in a row in a direction
  bool checkDirection(int row, int col, int rowDir, int colDir, int playerColor) {
    int count = 1; //count the piece we just droppped

    //check in one direction
    int r = row + rowDir;
    int c = col + colDir;
    while (r >= 0 && r < ROWS && c >= 0 && c < COLUMNS && board[r][c] == playerColor) {
      count++;
      r += rowDir;
      c += colDir;
    }

    //check opp direction
    r = row - rowDir;
    c = col - colDir;
    while (r >= 0 && r < ROWS && c >= 0 && c < COLUMNS && board[r][c] == playerColor) {
      count++;
      r -= rowDir;
      c -= colDir;
    }

    return count >= 4;
  }

  //reset just the board but keep scores
  void resetBoard() {
    board = List.generate(ROWS, (_) => List.filled(COLUMNS, EMPTY));
    isMyTurn = false;
    gameOver = false;
    winner = null;
    bomb = false;
  }
}

//BLOC state
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
        // Play sound effect
        if (gameState.gameOver && gameState.winner == YELLOW) {
          AState(AudioPlayer()).playWinSoundEffect();
        } else if (gameState.bomb) {
          AState(AudioPlayer()).playBombSoundEffect();
        } else {
          AState(AudioPlayer()).play();
        }

        // Switch turns
        gameState.isMyTurn = false;

        // Send move to server
        if (currentState.theServer != null) {
          Map<String, dynamic> message = {
            'type': 'move',
            'column': column,
            'bomb': gameState.bomb
          };
          currentState.theServer!.write(jsonEncode(message));
        }

        updateGameState(gameState);
      }
    }
  }

//update the receiveServerData method in the client's ConnectionCubit
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
      bool bomb = data['bomb'] ?? false;

      if (data.containsKey('gameState')) {
        gameState.updateFromJson(data['gameState']);
      }

      // Play sound effect based on server's move
      if (gameState.gameOver && gameState.winner == RED) {
        AState(AudioPlayer()).playWinSoundEffect();
      } else if (bomb) {
        AState(AudioPlayer()).playBombSoundEffect();
      } else {
        AState(AudioPlayer()).play();
      }

    } else if (data['type'] == 'move_ack') {
      // Handle acknowledgment
      if (data.containsKey('gameState')) {
        gameState.updateFromJson(data['gameState']);
      }
    } else if (data['type'] == 'reset') {
      // Reset game
      if (data.containsKey('gameState')) {
        gameState.updateFromJson(data['gameState']);
      }
    }

    updateGameState(gameState);
  }

  //reset game when player clicks reset icon
  resetGame() {
    final currentState = state;
    final gameState = currentState.gameState;

    //save player scores before reset
    int playerScore = gameState.playerScore;
    int opponentScore = gameState.opponentScore;

    //create a new game state
    gameState.resetBoard();

    //send reset message to client
    //print( "sent reset request to server" );
    if (currentState.theServer != null) {
      Map<String, dynamic> message = {
        'type': 'reset',
        'gameState': gameState.toJson(),
      };
      currentState.theServer!.write(jsonEncode(message));
    }

    emit(ConnectionState( state.theServer, state.listened, gameState));
  }

  Future<void> connect() async {
    await Future.delayed(const Duration(seconds: 2));
    try {
      final socket = await Socket.connect('localhost', 9203);
      print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      update(socket);
    } catch (e) {
      print('Error connecting to server: $e');
      //try reconnecting again after a bit
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

void main() async {
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
              /*builder: (context, state){
                return Connect4ClientUI(title: header);
              }*/
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
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => {
              //print( "request to reset game"),
              cc.resetGame()
            },
            tooltip: "Reset Game",
          ),
          //display score
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

                        // Ensure we're using the correct orientation for the board
                        int displayRow = row;

                        // Create a unique key for each cell that changes when the cell's content changes
                        return Container(
                          // This key ensures the widget rebuilds when any cell in the column changes
                          //key: ValueKey('cell_${displayRow}_${col}_${cs.gameState.board[displayRow][col]}'),
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

          //connection status
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
        //print(error);
        sc.update("Connection error: $error");
      },
      onDone: () {
        sc.update("Server disconnected");
      },
    );
  }
}