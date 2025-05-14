//server
//goes first
//plays RED
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
const int RED = 1;      //server goes FIRST and plays RED (us)
const int YELLOW = 2;   //client plays YELLOW

//vv-- for sound effect --vv
class AState
{
  AudioPlayer thep;
  AState( this.thep);
  void play() // put these in the project/assets folder
  {
    //this is the sound effect when a token is "dropped" into a column
    thep.play(AssetSource('connect4_sound_effect.mp4'));
  }
  void playWinSoundEffect(){
    //this is the sound effect when a player wins
    thep.play( AssetSource('connect4_win_sound_effect.mp4'));
  }

  void playBombSoundEffect() {
    thep.play(AssetSource('bomb_sound_effect.mp4'));
  }
}

//keeps track of the current game
//and stores data like the board state, player scores, etc
//has functions that check if a move is valid, etc
class GameState {
  List<List<int>> board = List.generate(ROWS, (_) => List.filled(COLUMNS, EMPTY)); //the board is initially empty
  bool isMyTurn = true; //the server goes first by default
  int myColor = RED; //server plays RED
  int opponentColor = YELLOW; //client plays YELLOW
  bool gameOver = false; //the game is initially NOT over
  int? winner; //and we're initially NOT the winner
  bool bomb = false;

  //vv-- keep track of scores --v
  int playerScore = 0;
  int opponentScore = 0;

  GameState();

  //(useful for Hydrated Cubit)
  //deserializes board game & player scores for persistence across sessions
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

  //also useful for Hydrated Cubit
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
    return board[0][column] == EMPTY; // Check if the top cell in the column is empty
  }

  //if the move is valid, drop the token into the specified column
  //returns false if the game is NOT over
  //returns true if the game is OVER
  bool makeMove(int column, int playerColor, bool givenBomb) {
    if (!isValidMove(column)) return false;

    // Set bomb state based on input or random chance for RED player
    if (playerColor == RED && !givenBomb) {
      bomb = Random().nextDouble() < 0.1;
    } else {
      bomb = givenBomb;
    }

    int row = ROWS - 1;
    if (bomb) {
      // Clear out the whole column
      for (int k = ROWS-1; k >= 0; k--) {
        if (board[k][column] == EMPTY) break;
        board[k][column] = EMPTY;
      }
      row = ROWS-1;
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

  //check if the game is over after a move
  //if true, set gameOver to true
  //and set the winner
  void checkGameOver(int lastRow, int lastColumn, int playerColor) {
    //check horizontal
    if (checkDirection(lastRow, lastColumn, 0, 1, playerColor) ||
        //check vertical
        checkDirection(lastRow, lastColumn, 1, 0, playerColor) ||
        //check diagonal -->
        checkDirection(lastRow, lastColumn, -1, 1, playerColor) ||
        //check diagonal <--
        checkDirection(lastRow, lastColumn, 1, 1, playerColor)) {
      gameOver = true;
      winner = playerColor;

      //update player scores if gameOver was set to true in previous if statement ^^
      if (winner == RED) {
        playerScore += 1;
      } else if (winner == YELLOW) {
        opponentScore += 1;
      }

      return;
    }

    //check for draw??
    //(this only happens when the board is completely filled and no one can make a move anymore)
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

  //check if there are 4 in a row in a specific direction
  bool checkDirection(int row, int col, int rowDir, int colDir, int playerColor) {
    int count = 1; //start counting how many pieces there are in that direction
                  //but start with the count at 1 since we just placed one

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
    isMyTurn = true;
    gameOver = false;
    winner = null;
  }
}

//Bloc state
class ConnectionState {
  bool listening = false;
  Socket? theClient = null;
  bool listened = false;
  GameState gameState = GameState();

  ConnectionState(this.listening, this.theClient, this.listened, this.gameState);
}

//use Hydrated Cubit to allow state persistence across sessions
class ConnectionCubit extends HydratedCubit<ConnectionState> {
  ConnectionCubit() : super(ConnectionState(false, null, false, GameState())) {
    if (state.theClient == null) {
      connect();
    }

  }
  //ONLY save the game state across sessions
  //DON'T save if we're connected to the client
  @override
  Map<String, dynamic>? toJson(ConnectionState state) {
    return {
      //'listening': state.listening, --> should not serialize this since we need to reconnect when we run an app again
      //'listened': state.listened, --> also don't serialize this
      'gameState': state.gameState.toJson(),

    };
  }

  //deserialize for hydrated cubit
  @override
  ConnectionState? fromJson(Map<String, dynamic> json) {
    try {
      return ConnectionState(
        //json['listening'] as bool,
        false,
        null, // Socket can't be serialized
        //json['listened'] as bool,
        false,
        GameState()..fromJson(json['gameState']),
      );
    } catch (_) {
      return null;
    }
  }

  update(bool b, Socket s) {
    emit(ConnectionState(b, s, state.listened, state.gameState));
  }

  updateListen() {
    emit(ConnectionState(true, state.theClient, true, state.gameState));
  }

  updateGameState(GameState gs) {
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
      if (gameState.makeMove(column, RED, false)) {
        // Play sound effect based on game state
        if (gameState.gameOver && gameState.winner == RED) {
          AState(AudioPlayer()).playWinSoundEffect();
        } else if (gameState.bomb) {
          AState(AudioPlayer()).playBombSoundEffect();
        } else {
          AState(AudioPlayer()).play();
        }

        // Switch turns
        gameState.isMyTurn = false;

        // Send move to client with bomb information
        if (currentState.theClient != null) {
          Map<String, dynamic> message = {
            'type': 'move',
            'column': column,
            'bomb': gameState.bomb,
            'gameState': gameState.toJson(),
          };
          currentState.theClient!.write(jsonEncode(message));
        }

        updateGameState(gameState);
      }
    }
  }

  receiveClientMove(Map<String, dynamic> data) {
    final currentState = state;
    final gameState = currentState.gameState;

    if (data['type'] == 'reset') {
      // Handle reset request
      if (data.containsKey('gameState')) {
        gameState.updateFromJson(data['gameState']);
      }
    } else if (data['type'] == 'move') {
      int column = data['column'];
      bool bomb = data['bomb'] ?? false;

      // Update board with client's move
      if (gameState.makeMove(column, YELLOW, bomb)) {
        // Play sound effect based on outcome
        if (gameState.gameOver && gameState.winner == YELLOW) {
          AState(AudioPlayer()).playWinSoundEffect();
        } else if (bomb) {
          AState(AudioPlayer()).playBombSoundEffect();
        } else {
          AState(AudioPlayer()).play();
        }

        // Switch turns back to server
        gameState.isMyTurn = true;

        updateGameState(gameState);

        // Send acknowledgment to client with updated game state
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

      //send initial state of the game
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Directory addx = await getApplicationDocumentsDirectory();
  String add = addx.path;
  HydratedBloc.storage = await HydratedStorage.build
    ( storageDirectory: HydratedStorageDirectory
      ( (await getApplicationDocumentsDirectory()).path,),
  );
  runApp(const Connect4Server());
}

class Connect4Server extends StatelessWidget {

  static const String header = "Connect4Server";
  const Connect4Server( {super.key} );
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
              //builder: (context, state) => Connect4ServerUI(),
              builder: (context, state ){
                return Connect4ServerUI(title: header);
              }
            ),
          ),
        ),
      ),
    );
  }
}

class Connect4ServerUI extends StatelessWidget {
  final String title;
  const Connect4ServerUI( {super.key, required this.title} );
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
              //print( "request to reset game"),
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
          //connect4 status
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

                  // board
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
          else if (decodedMessage['type'] == 'reset') {
            cc.receiveClientMove(decodedMessage);
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
        sc.update("Player 2 disconnected");
      },
    );
  }
}