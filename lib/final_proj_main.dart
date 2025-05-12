import 'package:flutter/material.dart';

void main() {
  runApp(Connect4App());
}

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
  int currentPlayer = 1; // 1 = Red, 2 = Yellow
  bool gameOver = false;
  String winnerText = '';

  void dropDisc(int col) {
    if (gameOver) return;

    for (int row = rows - 1; row >= 0; row--) {
      if (board[row][col] == 0) {
        setState(() {
          board[row][col] = currentPlayer;
          if (checkWinner(row, col, currentPlayer)) {
            gameOver = true;
            winnerText = currentPlayer == 1 ? "Red Wins!" : "Yellow Wins!";
          } else {
            currentPlayer = currentPlayer == 1 ? 2 : 1;
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
      currentPlayer = 1;
      gameOver = false;
      winnerText = '';
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
        title: Text("Connect 4"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: resetGame,
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
          if( currentPlayer == 1 )
            Text(
              "Red's Turn",
              style: TextStyle( fontSize: 24, fontWeight: FontWeight.normal)
            )else Text(
            "Yellow's Turn",
              style: TextStyle( fontSize: 24, fontWeight: FontWeight.normal)
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
