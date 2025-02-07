// Barrett Koster
// This is a finished flutter counter program.
// I am converting it to Bloc.

/*import "dart:math";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:heidi_flutter/dice1.dart";

class SumState {
  int _counter;

  SumState(this._counter);
}

class SumCubit extends Cubit<SumState>{
  SumCubit(): super ( SumState(0) );

  void _incrementCounter( int val ) {
    // This call to setState tells the Flutter framework that something has
    // changed in this State, which causes it to rerun the build method below
    // so that the display can reflect the updated values. If we changed
    // _counter without calling setState(), then the build method would not be
    // called again, and so nothing would appear to happen.

    emit(SumState(state._counter + val));
  }
}

void main(){
  runApp( Yahtzee() );
}

class Yahtzee extends StatelessWidget{
  Yahtzee( {super.key} );

  @override
  Widget build( BuildContext context ){
    return BlocProvider<SumCubit> (
      create: ( context ) => SumCubit(),
      child: MaterialApp(
        title: "heidi's counter",
        home: YahtzeeHome()
      )
    );
  }
}

class YahtzeeHome extends StatelessWidget {
  @override
  Widget build( BuildContext context ){
    return Scaffold(
      appBar: AppBar( title: const Text("Heidi's timer") ),
      body: BlocBuilder<SumCubit, SumState>(
        builder: (context, sumState){
          return Column(
            children: [
              FloatingActionButton(
                  onPressed:(){ _incrementCounter(); },
                  child: const Text( "increment" ),
                  ),
            ],
          );
        }
      )
    );
  }
}*/