// s4.dart
// heidi vasquez

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";

const int BOARD_SIZE = 10; // 10x10 board
const int RACK_SIZE = 7;  // 7 letters per player

//letter tile
class Tile {
  String letter;
  bool placed = false;

  Tile(this.letter);

  Map<String, dynamic> toJson() => {
    'letter': letter,
    'placed': placed,
  };

  static Tile fromJson(Map<String, dynamic> json) {
    var tile = Tile(json['letter']);
    tile.placed = json['placed'];
    return tile;
  }
}

//game state
class GameState {
  List<List<String?>> board = List.generate(BOARD_SIZE, (_) => List.filled(BOARD_SIZE, null));
  List<Tile> letterBag = [];
  List<Tile> playerRack = [];
  int score = 0;
  bool isMyTurn = true;

  GameState() {
    initLetterBag();
    drawTiles();
  }

  void initLetterBag() {
    //hard coded tiles
    //https://www.amazon.com/Scrabble-Letters-Crossword-Numbers-Projects/dp/B08W5CWT72#:~:text=Each%20set%20of%20100%20uses,%2D1%2C%20and%202%20Blanks.
    addToLetterBag('A', 9);
    addToLetterBag('B', 2);
    addToLetterBag('C', 2);
    addToLetterBag('D', 4);
    addToLetterBag('E', 12);
    addToLetterBag('F', 2);
    addToLetterBag('G', 3);
    addToLetterBag('H', 2);
    addToLetterBag('I', 9);
    addToLetterBag('J', 1);
    addToLetterBag('K', 1);
    addToLetterBag('L', 4);
    addToLetterBag('M', 2);
    addToLetterBag('N', 6);
    addToLetterBag('O', 8);
    addToLetterBag('P', 2);
    addToLetterBag('Q', 1);
    addToLetterBag('R', 6);
    addToLetterBag('S', 4);
    addToLetterBag('T', 6);
    addToLetterBag('U', 4);
    addToLetterBag('V', 2);
    addToLetterBag('W', 2);
    addToLetterBag('X', 1);
    addToLetterBag('Y', 2);
    addToLetterBag('Z', 1);

    //now shuffle the bag
    letterBag.shuffle();
  }

  void addToLetterBag(String letter, int count) {
    for (int i = 0; i < count; i++) {
      letterBag.add(Tile(letter));
    }
  }

  void drawTiles() {
    while (playerRack.length < RACK_SIZE && letterBag.isNotEmpty) {
      playerRack.add(letterBag.removeAt(0));
    }
  }

  //convert to json
  Map<String, dynamic> toJson() {
    return {
      'board': board,
      'bagCount': letterBag.length,
      'isMyTurn': isMyTurn,
      'score': score,
    };
  }
}

//bloc state
class ConnectionState {
  bool listening = false;
  Socket? theClient = null;
  bool listened = false;
  GameState gameState = GameState();
  List<String?> tempBoard = List.filled(BOARD_SIZE * BOARD_SIZE, null);
  int lettersPlaced = 0;

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

  updateGameState(GameState gs) {
    emit(ConnectionState(state.listening, state.theClient, state.listened, gs));
  }

  placeTile(int index, Tile tile) {
    final currentState = state;
    final gameState = currentState.gameState;
    final row = index ~/ BOARD_SIZE;
    final col = index % BOARD_SIZE;

    if (gameState.isMyTurn && gameState.board[row][col] == null) {
      tile.placed = true;
      gameState.board[row][col] = tile.letter;
      currentState.lettersPlaced++;
      updateGameState(gameState);
    }
  }

  removeTile(int index) {
    final currentState = state;
    final gameState = currentState.gameState;
    final row = index ~/ BOARD_SIZE;
    final col = index % BOARD_SIZE;

    if (gameState.isMyTurn && gameState.board[row][col] != null) {
      //mark the tile as placed
      for (var tile in gameState.playerRack) {
        if (tile.letter == gameState.board[row][col] && tile.placed) {
          tile.placed = false;
          break;
        }
      }

      gameState.board[row][col] = null;
      currentState.lettersPlaced--;
      updateGameState(gameState);
    }
  }

  endTurn() {
    print( "inside of end turn function" );
    //if (state.lettersPlaced > 0) {
      final currentState = state;
      final gameState = currentState.gameState;

      //now update the score
      gameState.score += currentState.lettersPlaced;
      //and remove the tile
      gameState.playerRack.removeWhere((tile) => tile.placed);
      //place new tiles
      gameState.drawTiles();
      //now switch turns to the other player
      gameState.isMyTurn = false;
      currentState.lettersPlaced = 0;
      //now write the this msg to the client
      print( "about to send the msg to the client" );
      if (currentState.theClient != null) {
        Map<String, dynamic> message = {
          'type': 'turn_end',
          'gameState': {
            'board': gameState.board,
            'bagCount': gameState.letterBag.length,
            'isMyTurn': true,
          },
          'rack': gameState.playerRack.map((tile) => tile.toJson()).toList(),
          'lettersDrawn': currentState.lettersPlaced,
        };
        currentState.theClient!.write(jsonEncode(message));
        print( "done sending msg to client" );
      }

      updateGameState(gameState);
    //}
  }

  receiveClientMove(Map<String, dynamic> data) {
    final currentState = state;
    final gameState = currentState.gameState;

    //update the board with what you received from the other player
    if (data.containsKey('board')) {
      List<List<dynamic>> newBoard = List<List<dynamic>>.from(data['board']);
      for (int i = 0; i < BOARD_SIZE; i++) {
        for (int j = 0; j < BOARD_SIZE; j++) {
          gameState.board[i][j] = newBoard[i][j];
        }
      }
    }

    //now update the bag of tiles
    if (data.containsKey('lettersDrawn')) {
      int clientLettersDrawn = data['lettersDrawn'];
      for (int i = 0; i < clientLettersDrawn; i++) {
        if (gameState.letterBag.isNotEmpty) {
          gameState.letterBag.removeAt(0);
        }
      }
    }

    //switch turns to yourself
    gameState.isMyTurn = true;
    updateGameState(gameState);

    //let the client know that we've received their update
    if (currentState.theClient != null) {
      Map<String, dynamic> ackMessage = {
        'type': 'move_ack',
        'gameState': {
          'board': gameState.board,
          'bagCount': gameState.letterBag.length,
          'isMyTurn': false, //server's turn now
        }
      };
      currentState.theClient!.write(jsonEncode(ackMessage));
    }
  }

  Future<void> connect() async {
    await Future.delayed(const Duration(seconds: 2));
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, 9203);
    print("Scrabble server started and waiting for a player to join...");

    server.listen((client) {
      emit(ConnectionState(true, client, state.listened, state.gameState));

      //send initial state of the game
      //server is initially active/player 1
      if (client != null) {
        Map<String, dynamic> message = {
          'type': 'game_init',
          'gameState': {
            'board': state.gameState.board,
            'bagCount': state.gameState.letterBag.length,
            'isMyTurn': false,
          }
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
  SaidCubit() : super(SaidState("Scrabble server started...\n"));

  void update(String s) {
    emit(SaidState("${state.said}\n$s"));
  }
}

void main() {
  runApp(ScrabbleServer());
}

class ScrabbleServer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Scrabble Server",
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BlocProvider<ConnectionCubit>(
        create: (context) => ConnectionCubit(),
        child: BlocBuilder<ConnectionCubit, ConnectionState>(
          builder: (context, state) => BlocProvider<SaidCubit>(
            create: (context) => SaidCubit(),
            child: BlocBuilder<SaidCubit, SaidState>(
              builder: (context, state) => ScrabbleServerUI(),
            ),
          ),
        ),
      ),
    );
  }
}

class ScrabbleServerUI extends StatelessWidget {
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
        title: Text("Scrabble - Player 1"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                "Score: ${cs.gameState.score}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Game status
          Container(
            padding: EdgeInsets.all(8),
            color: cs.gameState.isMyTurn ? Colors.green[100] : Colors.red[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  cs.gameState.isMyTurn ? "Your Turn" : "Opponent's Turn",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Tiles in bag: ${cs.gameState.letterBag.length}"),
              ],
            ),
          ),

          // Scrabble board
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                ),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: BOARD_SIZE,
                  ),
                  itemCount: BOARD_SIZE * BOARD_SIZE,
                  itemBuilder: (context, index) {
                    int row = index ~/ BOARD_SIZE;
                    int col = index % BOARD_SIZE;

                    return DragTarget<Tile>(
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            color: cs.gameState.board[row][col] != null ? Colors.amber[100] : Colors.brown[50],
                          ),
                          alignment: Alignment.center,
                          child: cs.gameState.board[row][col] != null
                              ? GestureDetector(
                            onTap: cs.gameState.isMyTurn ? () => cc.removeTile(index) : null,
                            child: Text(
                              cs.gameState.board[row][col]!,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                              : null,
                        );
                      },
                      onAccept: (tile) {
                        if (cs.gameState.isMyTurn) {
                          cc.placeTile(index, tile);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ),

          // Player rack
          if (cs.theClient != null)
            Container(
              height: 80,
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.brown[200],
                borderRadius: BorderRadius.circular(5),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: cs.gameState.playerRack.length,
                itemBuilder: (context, index) {
                  final tile = cs.gameState.playerRack[index];
                  if (tile.placed) return SizedBox(width: 50);

                  return Draggable<Tile>(
                    data: tile,
                    feedback: Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        tile.letter,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    childWhenDragging: Container(
                      width: 50,
                      height: 50,
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Container(
                      width: 50,
                      height: 50,
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tile.letter,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          ElevatedButton(onPressed:(){
            print( cs.gameState.isMyTurn );
            print( cs.lettersPlaced );
            if( cs.gameState.isMyTurn ){
              print( "it's my turn" );
              cc.endTurn();
            }else{
              print( "it's not my turn" );
            }
            //cs.gameState.isMyTurn ? () => cc.endTurn() : null;
            print( "PRESSED BUTTON" );
          }, child: Text("End turn")),

          // End turn button
          /*Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: cs.gameState.isMyTurn && cs.lettersPlaced > 0 ? () => cc.endTurn() : null,
              child: Text("End Turn"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),*/

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
          if (decodedMessage['type'] == 'turn_end') {
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
        cs.theClient!.close();
      },
    );
  }
}