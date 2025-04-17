// game_state.dart
// Barrett Koster 2025

import "package:flutter_bloc/flutter_bloc.dart";

// This is where you put whatever the game is about.

class GameState
{
  bool iStart;
  bool myTurn;
  List<String> board;
  bool gameOver;
  bool? iWon;

  GameState( this.iStart, this.myTurn, this.board, {this.gameOver = false, this.iWon} );
}

class GameCubit extends Cubit<GameState>
{
  static final String d = ".";
  GameCubit( bool myt ): super( GameState( myt, myt, [d,d,d,d,d,d,d,d,d] )); 

  update( int where, String what )
  {
    state.board[where] = what;
    state.myTurn = !state.myTurn;
    emit( GameState(state.iStart,state.myTurn,state.board) ) ;
  }

  resign(){
    emit( GameState(state.iStart,state.myTurn,state.board, gameOver: true, iWon: false) ) ;
  }

  //this function detects if someone has won the game
  //we will call it before letting the user make a move
  bool? checkWin() {
    //check for a horizontal win
    for (int i = 0; i < 9; i += 3) {
      if (state.board[i] != d &&
          state.board[i] == state.board[i+1] &&
          state.board[i] == state.board[i+2]) {
        return state.board[i] == "x"; // returns true if X wins, false if O wins
      }
    }

    //check for a vertical win
    for (int i = 0; i < 3; i++) {
      if (state.board[i] != d &&
          state.board[i] == state.board[i+3] &&
          state.board[i] == state.board[i+6]) {
        return state.board[i] == "x";
      }
    }

    //check for a diagonal win
    if (state.board[0] != d &&
        state.board[0] == state.board[4] &&
        state.board[0] == state.board[8]) {
      return state.board[0] == "x";
    }

    if (state.board[2] != d &&
        state.board[2] == state.board[4] &&
        state.board[2] == state.board[6]) {
      return state.board[2] == "x";
    }

    //check if there was a draw
    if (!state.board.contains(d)) {
      return null;
    }
    //otherwise, the game is still in progress
    return null;
  }

  // Someone played x or o in this square.  (numbered from
  // upper left 0,1,2, next row 3,4,5 ... 
  // Update the board and emit.
  play( int where )
  { String mark = state.myTurn==state.iStart? "x":"o";
    state.board[where] = mark;
    state.myTurn = !state.myTurn;

    //check if anyone has won before making the move
    final winner = checkWin();
    bool gameOver = winner != null;
    bool? iWon;
    if( gameOver ){
      iWon = winner == null ? null : winner == state.iStart;
    }
    emit( GameState(state.iStart,state.myTurn,state.board, gameOver: gameOver, iWon: iWon) ) ;
  }

  // incoming messages are sent here for the game to do
  // whatever with.  in this case, "sq NUM" messages ..
  // we send the number to be played.
  void handle( String msg )
  { List<String> parts = msg.split(" ");
    if ( parts[0] == "sq" )
    { int sqNum = int.parse(parts[1]);
      play(sqNum);
    }

  }
}