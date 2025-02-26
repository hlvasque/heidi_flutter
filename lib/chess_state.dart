//chess_state.dart

import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'coords.dart';

class ChessState {
  List<List<String>> board; // 8x8 chessboard state
  int turnCount; // The number of turns taken, starting at 0

  ChessState({required this.board, required this.turnCount});

  // Factory constructor to load the state from JSON
  factory ChessState.fromJson(Map<String, dynamic> json) {
    var boardData = (json['board'] as List)
        .map((e) => List<String>.from(e))
        .toList(); // Convert the board list of lists
    return ChessState(
      board: boardData,
      turnCount: json['turnCount'] as int,
    );
  }

  // Method to convert ChessState to JSON
  Map<String, dynamic> toJson() {
    return {
      'board': board, // Convert the 2D board list to a JSON-friendly format
      'turnCount': turnCount, // Include the turn count
    };
  }
}

class ChessCubit extends HydratedCubit<ChessState> {
  ChessCubit()
      : super(ChessState(
    board: [
      ['r.', 'p', ' ', ' ', ' ', ' ', 'P', 'R.'],
      ['n', 'p', ' ', ' ', ' ', ' ', 'P', 'N'],
      ['b', 'p', ' ', ' ', ' ', ' ', 'P', 'B'],
      ['q', 'p', ' ', ' ', ' ', ' ', 'P', 'Q'],
      ['k', 'p', ' ', ' ', ' ', ' ', 'P', 'K'],
      ['b', 'p', ' ', ' ', ' ', ' ', 'P', 'B'],
      ['n', 'p', ' ', ' ', ' ', ' ', 'P', 'N'],
      ['r.', 'p', ' ', ' ', ' ', ' ', 'P', 'R.'],
    ],
    turnCount: 0,
  ));

  // Update the board and turn count when a move is made
  void update(Coords fromHere, Coords toHere) {
    state.board[toHere.c][toHere.r] = state.board[fromHere.c][fromHere.r];
    state.board[fromHere.c][fromHere.r] = " ";
    emit(ChessState(
      board: state.board,
      turnCount: state.turnCount + 1,
    ));
  }

  // HydratedCubit overrides to handle state serialization/deserialization
  @override
  ChessState fromJson(Map<String, dynamic> json) {
    if (json == null) {
      // If storage is empty or unavailable, return a default state
      return ChessState(
        board: [
          ['r.', 'p', ' ', ' ', ' ', ' ', 'P', 'R.'],
          ['n', 'p', ' ', ' ', ' ', ' ', 'P', 'N'],
          ['b', 'p', ' ', ' ', ' ', ' ', 'P', 'B'],
          ['q', 'p', ' ', ' ', ' ', ' ', 'P', 'Q'],
          ['k', 'p', ' ', ' ', ' ', ' ', 'P', 'K'],
          ['b', 'p', ' ', ' ', ' ', ' ', 'P', 'B'],
          ['n', 'p', ' ', ' ', ' ', ' ', 'P', 'N'],
          ['r.', 'p', ' ', ' ', ' ', ' ', 'P', 'R.'],
        ],
        turnCount: 0,
      );
    }
    return ChessState.fromJson(json); // Deserialize JSON back into ChessState
  }

  @override
  Map<String, dynamic> toJson(ChessState state) {
    return state.toJson(); // Serialize the ChessState into JSON
  }
}
