/*import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'game_cubit.dart';
import 'final_c4_2.dart';

void main() {
  runApp(const Connect4App());
}

class Connect4App extends StatelessWidget {
  const Connect4App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => GameCubit(),
        child: const GameScreen(),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final SocketClient socketClient;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<GameCubit>();

    socketClient = SocketClient(onBoardUpdate: (data) {
      final board = data
          .split('\n')
          .map((row) => row.split(','))
          .toList();
      cubit.updateBoard(board);
    });

    socketClient.connect();
  }

  void _makeMove(int col) {
    final cubit = context.read<GameCubit>();
    final player = cubit.state.currentPlayer;
    socketClient.sendMove(player, col);
    cubit.switchPlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect 4')),
      body: BlocBuilder<GameCubit, GameState>(
        builder: (context, state) {
          return Column(
            children: [
              for (int r = 0; r < state.board.length; r++)
                Row(
                  children: [
                    for (int c = 0; c < state.board[r].length; c++)
                      GestureDetector(
                        onTap: () => _makeMove(c),
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.all(4),
                          color: state.board[r][c] == ' '
                              ? Colors.grey[300]
                              : (state.board[r][c] == 'X'
                              ? Colors.red
                              : Colors.yellow),
                          child: Center(
                            child: Text(state.board[r][c]),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}*/
