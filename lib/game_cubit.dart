import 'package:flutter_bloc/flutter_bloc.dart';

class GameState {
  final List<List<String>> board;
  final String currentPlayer;

  GameState({required this.board, required this.currentPlayer});

  GameState copyWith({List<List<String>>? board, String? currentPlayer}) {
    return GameState(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
    );
  }
}

class GameCubit extends Cubit<GameState> {
  GameCubit()
      : super(GameState(
    board: List.generate(6, (_) => List.filled(7, ' ')),
    currentPlayer: 'X',
  ));

  void updateBoard(List<List<String>> newBoard) {
    emit(state.copyWith(board: newBoard));
  }

  void switchPlayer() {
    emit(state.copyWith(
      currentPlayer: state.currentPlayer == 'X' ? 'O' : 'X',
    ));
  }
}
