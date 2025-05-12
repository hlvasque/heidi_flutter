import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Game State class
class GameState {
  final List<List<int>> board;
  final int currentPlayer;
  final bool gameOver;
  final String winnerText;
  final bool isMyTurn;

  GameState({
    required this.board,
    required this.currentPlayer,
    required this.gameOver,
    required this.winnerText,
    required this.isMyTurn,
  });

  factory GameState.initial() {
    return GameState(
      board: List.generate(6, (_) => List.filled(7, 0)),
      currentPlayer: 1,
      gameOver: false,
      winnerText: '',
      isMyTurn: true,
    );
  }

  GameState copyWith({
    List<List<int>>? board,
    int? currentPlayer,
    bool? gameOver,
    String? winnerText,
    bool? isMyTurn,
  }) {
    return GameState(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      gameOver: gameOver ?? this.gameOver,
      winnerText: winnerText ?? this.winnerText,
      isMyTurn: isMyTurn ?? this.isMyTurn,
    );
  }
}

// Game Cubit class
class GameCubit extends Cubit<GameState> {
  Socket? clientConnection;

  GameCubit() : super(GameState.initial());

  void setClientConnection(Socket connection) {
    clientConnection = connection;
  }

  void dropDisc(int col) {
    if (state.gameOver || !state.isMyTurn) return;

    for (int row = 5; row >= 0; row--) {
      if (state.board[row][col] == 0) {
        final newBoard = [...state.board.map((r) => [...r])];
        newBoard[row][col] = state.currentPlayer;

        final won = _checkWinner(newBoard, row, col, state.currentPlayer);
        final nextPlayer = state.currentPlayer == 1 ? 2 : 1;

        emit(state.copyWith(
          board: newBoard,
          gameOver: won,
          winnerText: won ? (state.currentPlayer == 1 ? "Red Wins!" : "Yellow Wins!") : '',
          currentPlayer: won ? state.currentPlayer : nextPlayer,
          isMyTurn: !won,
        ));

        if (clientConnection != null) {
          clientConnection!.write(
              "MOVE:$row:$col:${state.currentPlayer}${won ? ":GAMEOVER:${state.winnerText}" : ""}"
          );
        }
        break;
      }
    }
  }

  void applyClientMove(int row, int col) {
    if (state.gameOver || state.board[row][col] != 0) return;

    final newBoard = [...state.board.map((r) => [...r])];
    newBoard[row][col] = state.currentPlayer;

    final won = _checkWinner(newBoard, row, col, state.currentPlayer);
    final nextPlayer = state.currentPlayer == 1 ? 2 : 1;

    emit(state.copyWith(
      board: newBoard,
      gameOver: won,
      winnerText: won ? (state.currentPlayer == 1 ? "Red Wins!" : "Yellow Wins!") : '',
      currentPlayer: nextPlayer,
      isMyTurn: true,
    ));
  }

  void resetGame() {
    emit(GameState.initial());
    if (clientConnection != null) {
      clientConnection!.write("RESET");
    }
  }

  bool _checkWinner(List<List<int>> board, int row, int col, int player) {
    return _checkDirection(board, row, col, player, 1, 0) ||
        _checkDirection(board, row, col, player, 0, 1) ||
        _checkDirection(board, row, col, player, 1, 1) ||
        _checkDirection(board, row, col, player, 1, -1);
  }

  bool _checkDirection(List<List<int>> board, int row, int col, int player, int dRow, int dCol) {
    int count = 1;
    for (int dir = -1; dir <= 1; dir += 2) {
      int r = row + dir * dRow;
      int c = col + dir * dCol;
      while (r >= 0 && r < 6 && c >= 0 && c < 7 && board[r][c] == player) {
        count++;
        r += dir * dRow;
        c += dir * dCol;
      }
    }
    return count >= 4;
  }
}

// Connect 4 Game UI
class Connect4Game extends StatelessWidget {
  final Socket clientConnection;
  const Connect4Game({Key? key, required this.clientConnection}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = GameCubit();
        cubit.setClientConnection(clientConnection);
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Connect 4')),
        body: Center(
          child: BlocBuilder<GameCubit, GameState>(
            builder: (context, state) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (state.gameOver)
                    Text(
                      state.winnerText,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  for (int row = 0; row < 6; row++)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int col = 0; col < 7; col++)
                          GestureDetector(
                            onTap: () => context.read<GameCubit>().dropDisc(col),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: state.board[row][col] == 1
                                    ? Colors.red
                                    : state.board[row][col] == 2
                                    ? Colors.yellow
                                    : Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                      ],
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<GameCubit>().resetGame(),
                    child: const Text('Reset'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
