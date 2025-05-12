/*import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

void main(){
  runApp( MyApp() );
}

TextStyle ts = TextStyle( fontSize: 30 );

class MyApp extends StatelessWidget{
  MyApp( {super.key} );

  @override
  Widget build( BuildContext context ){
    String title = "title";
    return MaterialApp(
      title: title,
      home: TopBloc( title: title )
    );
  }
}

class someState{
  int someData;
  someState( this.someData );
}

class someCubit extends Cubit<someState>{
  someCubit(): super( someState(0) );
  void increment(){
    emit( someState( state.someData + 1 ) );
  }
}

class TopBloc extends StatelessWidget{
  final String title;
  TopBloc( { required this.title, super.key } );
  @override
  Widget build( BuildContext context ){
    return BlocProvider<someCubit>(
      create: (context)=>someCubit(),
      child: BlocBuilder<someCubit, someState>(
        builder: (context, state)=> HomePage( title: title )
      )
    );
  }
}

class HomePage extends StatelessWidget{
  final String title;
  HomePage( {required this.title, super.key } );

  @override
  Widget build( BuildContext context ){
    someCubit sc = BlocProvider.of<someCubit>( context );
    return Scaffold (
      appBar: AppBar( title: Text( title, style: ts ) ),
      body: Column(
        children: [
          Text( "page1" ),
          Text( "State value: ${sc.state.someData}"),
          ElevatedButton (
            onPressed:(){
              sc.increment();
            },
            child: Text( "inc", style: ts)
          ),
          ElevatedButton(
            onPressed:(){
              Navigator.of( context ).push(
                MaterialPageRoute(
                  builder: (context)=>Route2( cc:cc )
                )
              );
            },
            child: Text( "next pg", style:ts )
          )
        ],
      )

    );
  }
}

class Route2 extends StatelessWidget{
  final String title = "Route2";
  final someCubit sc;
  Route2( {required this.sc, super.key } );

  @override
  Widget build( BuildContext context ){
    return BlocProvider<someCubit>.value(
      value: sc,
      child: BlocBuilder<someCubit, someState>(
        builder: (context, state ){
          return Scaffold(
            appBar: AppBar( title: Text( title, style: ts ) ),
            body: Column(
              children: [
                Text( "${sc.state.someData}" ),
                ElevatedButton()
              ],
            )
          );
        }
      )
    )
  }
}*/