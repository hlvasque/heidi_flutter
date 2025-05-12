// Barrett Koster
// working from notes from Suragch

/* To run this, run s4.dart (server) first, then run this c4.dart (client).
   The two should communicate.
*/

// client side of connection

import 'dart:io';
import 'dart:typed_data';

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class Connect4App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connect 4',
      home: Connect4Game(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Connect4Game extends StatefulWidget {
  @override
  _Connect4GameState createState() => _Connect4GameState();
}

class _Connect4GameState extends State<Connect4Game> {
  static const int rows = 6;
  static const int columns = 7;

  List<List<int>> board = List.generate(rows, (_) => List.filled(columns, 0));
  int currentPlayer = 1; // 1 = Red (server), 2 = Yellow (client)
  bool gameOver = false;
  String winnerText = '';
  Socket? serverConnection;
  bool isMyTurn = false; // Client starts second (Yellow)

  // Set the server connection reference
  void setServerConnection(Socket connection) {
    serverConnection = connection;
  }

  // Apply a move received from the server
  void applyServerMove(int row, int col, int player, bool isGameOver, String gameOverText) {
    setState(() {
      board[row][col] = player;

      if (isGameOver) {
        gameOver = true;
        winnerText = gameOverText;
      } else {
        currentPlayer = player == 1 ? 2 : 1;
        isMyTurn = player != 2; // It's my turn if the server just played Red
      }
    });
  }

  void dropDisc(int col) {
    if (gameOver || !isMyTurn) return;

    for (int row = rows - 1; row >= 0; row--) {
      if (board[row][col] == 0) {
        setState(() {
          board[row][col] = currentPlayer;
          if (checkWinner(row, col, currentPlayer)) {
            gameOver = true;
            winnerText = currentPlayer == 1 ? "Red Wins!" : "Yellow Wins!";
            // Send move and game over status to server
            if (serverConnection != null) {
              serverConnection!.write("MOVE:$col:$currentPlayer:GAMEOVER");
            }
          } else {
            currentPlayer = currentPlayer == 1 ? 2 : 1;
            isMyTurn = false; // Now it's the server's turn
            // Send move to server
            if (serverConnection != null) {
              serverConnection!.write("MOVE:$col:$currentPlayer");
            }
          }
        });
        break;
      }
    }
  }

  bool checkWinner(int row, int col, int player) {
    return checkDirection(row, col, player, 1, 0) || // Horizontal
        checkDirection(row, col, player, 0, 1) || // Vertical
        checkDirection(row, col, player, 1, 1) || // Diagonal \
        checkDirection(row, col, player, 1, -1); // Diagonal /
  }

  bool checkDirection(int row, int col, int player, int dRow, int dCol) {
    int count = 1;

    for (int dir = -1; dir <= 1; dir += 2) {
      int r = row + dir * dRow;
      int c = col + dir * dCol;

      while (r >= 0 && r < rows && c >= 0 && c < columns && board[r][c] == player) {
        count++;
        r += dir * dRow;
        c += dir * dCol;
      }
    }

    return count >= 4;
  }

  void resetGame() {
    setState(() {
      board = List.generate(rows, (_) => List.filled(columns, 0));
      currentPlayer = 1; // Game always starts with Red (server)
      gameOver = false;
      winnerText = '';
      isMyTurn = false; // Client (Yellow) doesn't get first turn
    });
  }

  Widget buildCell(int row, int col) {
    Color color;
    if (board[row][col] == 1) {
      color = Colors.red;
    } else if (board[row][col] == 2) {
      color = Colors.yellow;
    } else {
      color = Colors.grey[300]!;
    }

    return GestureDetector(
      onTap: () => dropDisc(col),
      child: Container(
        margin: EdgeInsets.all(2),
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Connect 4 (Client - Yellow)"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              resetGame();
              // Notify server about game reset
              if (serverConnection != null) {
                serverConnection!.write("RESET");
              }
            },
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (gameOver)
            Text(
              winnerText,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          SizedBox(height: 20),
          if(currentPlayer == 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    "Red's Turn ",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.normal)
                ),
                if(!isMyTurn)
                  Text(
                      "(Server's Turn)",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)
                  )
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    "Yellow's Turn ",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.normal)
                ),
                if(isMyTurn)
                  Text(
                      "(Your Turn)",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.yellow)
                  )
              ],
            ),

          // 👇 Using Builder to dynamically generate the board with its own BuildContext
          Builder(
            builder: (BuildContext context) {
              return Column(
                children: List.generate(rows, (row) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(columns, (col) => buildCell(row, col)),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ConnectionState {
  Socket? theServer = null; // Socket to connect to the server
  bool listened = false; // true == listening has been started on this
  _Connect4GameState? c4Game; // Reference to the game state

  ConnectionState(this.theServer, this.listened, this.c4Game);
}

class ConnectionCubit extends Cubit<ConnectionState> {
  // constructor. Try to connect when you start.
  ConnectionCubit() : super(ConnectionState(null, false, _Connect4GameState())) {
    if (state.theServer == null) {
      connect();
    }
  }

  update(Socket? s) {
    emit(ConnectionState(s, state.listened, state.c4Game));
  }

  updateListen() {
    emit(ConnectionState(state.theServer, true, state.c4Game));
  }

  // connect() is async, so it may take a while. When done, it
  // emit()s a new ConnectionState, to say that we are connected.
  Future<void> connect() async {
    await Future.delayed(const Duration(seconds: 2)); // adds drama
    try {
      // connect to the socket server
      final socket = await Socket.connect('localhost', 9203);
      print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      update(socket);
    } catch (e) {
      print('Error connecting to server: $e');
      // You might want to add a retry mechanism here
      Future.delayed(const Duration(seconds: 5), () {
        connect(); // Try to reconnect after 5 seconds
      });
    }
  }
}

class SaidState {
  String said;

  SaidState(this.said);
}

class SaidCubit extends Cubit<SaidState> {
  SaidCubit() : super(SaidState("Client started, connecting to server...\n"));

  void update(String s) {
    emit(SaidState("${state.said}\n$s"));
  }
}

void main() {
  runApp(Client());
}

class Client extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Connect 4 Client",
      home: BlocProvider<ConnectionCubit>(
        create: (context) => ConnectionCubit(),
        child: BlocBuilder<ConnectionCubit, ConnectionState>(
          builder: (context, state) => BlocProvider<SaidCubit>(
            create: (context) => SaidCubit(),
            child: BlocBuilder<SaidCubit, SaidState>(
              builder: (context, state) => Client2(),
            ),
          ),
        ),
      ),
    );
  }
}

class Client2 extends StatefulWidget {
  @override
  _Client2State createState() => _Client2State();
}

class _Client2State extends State<Client2> {
  final TextEditingController tec = TextEditingController();
  final _Connect4GameState gameState = _Connect4GameState();

  // Method to listen for server messages
  void listen(BuildContext context) {
    ConnectionCubit cc = BlocProvider.of<ConnectionCubit>(context);
    SaidCubit sc = BlocProvider.of<SaidCubit>(context);
    Socket s = cc.state.theServer!;

    s.listen(
          (Uint8List data) {
        final message = String.fromCharCodes(data);
        print('Server: $message');

        // Handle different message types
        if (message.startsWith("CHAT:")) {
          // Chat message from server
          final chatMessage = message.substring(5);
          sc.update("Server: $chatMessage");
        } else if (message.startsWith("MOVE:")) {
          // Move from the server
          final parts = message.split(":");
          if (parts.length >= 4) {
            final col = int.parse(parts[1]);
            final player = int.parse(parts[2]);

            // Find the row where the disc would land
            int row = -1;
            for (int r = _Connect4GameState.rows - 1; r >= 0; r--) {
              if (gameState.board[r][col] == 0) {
                row = r;
                break;
              }
            }

            if (row != -1) {
              final isGameOver = parts.length > 4 && parts[3] == "GAMEOVER";
              final gameOverText = isGameOver ? (player == 1 ? "Red Wins!" : "Yellow Wins!") : "";

              gameState.applyServerMove(row, col, player, isGameOver, gameOverText);

              // Log the move
              sc.update("Server made a move: column $col");
              if (isGameOver) {
                sc.update("Game over: $gameOverText");
              }
            }
          }
        } else if (message.startsWith("RESET")) {
          // Server requested a game reset
          gameState.resetGame();
          sc.update("Server reset the game");
        } else if (message.startsWith("DRAW")) {
          // Game ended in a draw
          gameState.gameOver = true;
          gameState.winnerText = "Game ended in a draw!";
          sc.update("Game ended in a draw");
        } else {
          // Unknown message type
          sc.update("Server: $message");
        }
      },
      onError: (error) {
        print('Error: $error');
        sc.update("Connection error: $error");
      },
      onDone: () {
        print('Server disconnected');
        sc.update("Server disconnected. Trying to reconnect...");
        cc.emit(ConnectionState(null, false, cc.state.c4Game)); // Reset the connection state
        cc.connect(); // Try to reconnect
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ConnectionCubit cc = BlocProvider.of<ConnectionCubit>(context);
    ConnectionState cs = cc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(context);

    // Update the game state reference in the connection cubit
    if (cs.c4Game == null) {
      cc.state.c4Game = gameState;
    }

    if (cs.theServer != null && !cs.listened) {
      // Give the game state a reference to the server connection
      gameState.setServerConnection(cs.theServer!);
      listen(context);
      cc.updateListen();
    }

    return Scaffold(
      appBar: AppBar(title: Text("Connect 4 Client")),
      body: Column(
        children: [
          // Connect 4 Game
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.blue[100],
              child: Center(
                child: gameState.build(context),
              ),
            ),
          ),
          // Chat Section
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // place to type and sent button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tec,
                          decoration: InputDecoration(
                            hintText: "Type message to server...",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      cs.theServer != null
                          ? ElevatedButton(
                        onPressed: () {
                          cs.theServer!.write("CHAT:${tec.text}");
                          sc.update("Client: ${tec.text}");
                          tec.clear();
                        },
                        child: Text("Send"),
                      )
                          : ElevatedButton(
                        onPressed: null,
                        child: Text("Connecting..."),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        child: cs.theServer != null
                            ? Text(sc.state.said)
                            : Text("Waiting for connection..."),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}