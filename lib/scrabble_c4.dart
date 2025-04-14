// c4.dart
//heidi vasquez

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
  List<Tile> playerRack = [];
  //bag initially has 98 tiles
  int bagCount = 98;
  int score = 0;
  bool isMyTurn = false;

  //generate random set of tiles
  GameState() {
    generateInitialRack();
  }

  void generateInitialRack() {
    String letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    Random rand = Random();
    for (int i = 0; i < RACK_SIZE; i++) {
      playerRack.add(Tile(letters[rand.nextInt(letters.length)]));
    }
  }

  void updateFromJson(Map<String, dynamic> json) {
    List<List<dynamic>> newBoard = List<List<dynamic>>.from(json['board']);
    for (int i = 0; i < BOARD_SIZE; i++) {
      for (int j = 0; j < BOARD_SIZE; j++) {
        board[i][j] = newBoard[i][j];
      }
    }

    bagCount = json['bagCount'];
    isMyTurn = json['isMyTurn'];
  }

  void updateRack(List<dynamic> rackJson) {
    playerRack.clear();
    for (var tileJson in rackJson) {
      playerRack.add(Tile.fromJson(tileJson));
    }
  }
}

//bloc state
class ConnectionState {
  Socket? theServer = null;
  bool listened = false;
  GameState gameState = GameState();
  int lettersPlaced = 0;
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
      //mark the tile as not placed
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
    //if (state.lettersPlaced > 0) {
      final currentState = state;
      final gameState = currentState.gameState;
      //update score
      gameState.score += currentState.lettersPlaced;
      //remove tile from our current deck
      int lettersDrawn = gameState.playerRack.where((tile) => tile.placed).length;
      gameState.playerRack.removeWhere((tile) => tile.placed);

      //pull new tiles from the bag
      if (gameState.bagCount >= lettersDrawn) {
        String letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        Random rand = Random();
        for (int i = 0; i < lettersDrawn; i++) {
          gameState.playerRack.add(Tile(letters[rand.nextInt(letters.length)]));
        }
        gameState.bagCount -= lettersDrawn;
      }

      //swtich turns
      gameState.isMyTurn = false;
      currentState.lettersPlaced = 0;

      //send the new state of the game to the other player
      if (currentState.theServer != null) {
        Map<String, dynamic> message = {
          'type': 'turn_end',
          'board': gameState.board,
          'lettersDrawn': lettersDrawn,
        };
        currentState.theServer!.write(jsonEncode(message));
      }

      updateGameState(gameState);
    //}
  }

  receiveServerData(Map<String, dynamic> data) {
    final currentState = state;
    final gameState = currentState.gameState;

    if (data['type'] == 'game_init') {
      //initialize game
      gameState.updateFromJson(data['gameState']);

      //create a new board based on what we got from the server/player 1
      gameState.generateInitialRack();
    } else if (data['type'] == 'turn_end') {
      //update the board
      gameState.updateFromJson(data['gameState']);

      if (data.containsKey('rack')) {
        gameState.updateRack(data['rack']);
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
      //try to connect again after a bit
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
  SaidCubit() : super(SaidState("Connecting to Scrabble server...\n"));

  void update(String s) {
    emit(SaidState("${state.said}\n$s"));
  }
}

void main() {
  runApp(ScrabbleClient());
}

class ScrabbleClient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Scrabble Client",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BlocProvider<ConnectionCubit>(
        create: (context) => ConnectionCubit(),
        child: BlocBuilder<ConnectionCubit, ConnectionState>(
          builder: (context, state) => BlocProvider<SaidCubit>(
            create: (context) => SaidCubit(),
            child: BlocBuilder<SaidCubit, SaidState>(
              builder: (context, state) => ScrabbleClientUI(),
            ),
          ),
        ),
      ),
    );
  }
}

class ScrabbleClientUI extends StatelessWidget {
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
        title: Text("Scrabble - Player 2"),
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
                Text("Tiles in bag: ${cs.gameState.bagCount}"),
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
          if (cs.theServer != null)
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

          // End turn button
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
          } else if (decodedMessage['type'] == 'turn_end') {
            sc.update("It's your turn now");
          }
        } catch (e) {
          sc.update("Error processing message: $e");
        }
      },
      onError: (error) {
        print(error);
        sc.update("Connection error: $error");
        cs.theServer!.close();
      },
    );
  }
}