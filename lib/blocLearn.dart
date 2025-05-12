/*import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

TextStyle ts = TextStyle( fontSize: 30 );

void main(){
  runApp( MyApp() );
}

class MyApp extends StatelessWidget{
  MyApp( {super.key} );
  @override
  Widget build( BuildContext context ){
    String title = "MyApp";
    return MaterialApp(
      title: "MaterialApp",
      home: TopBloc( title: title ),
    );
  }
}

class SomeState {
  int someInfo;
  SomeState( this.someInfo );
}

class SomeCubit extends Cubit<SomeState>{
  SomeCubit(): super( SomeState( 0 ) );
  void increment(){
    emit( SomeState( state.someInfo + 1) );
  }
}

class TopBloc extends StatelessWidget{
  final String title;
  TopBloc( {required this.title, super.key } );

  @override
  Widget build( BuildContext context ){
    return BlocProvider<SomeCubit>(
      create: (context)=>SomeCubit(),
      child: BlocBuilder<SomeCubit, SomeState>(
        builder: ( context, state )=> HomePage( title: title )
      )
    );
  }
}

class HomePage extends StatelessWidget {
  final String title;
  HomePage( {required this.title, super.key });

  @override
  Widget build( BuildContext context ){
    SomeCubit cc = BlocProvider.of<SomeCubit>(context);

    return Scaffold(
      appBar: AppBar( title: Text( title, style: ts ) ),
      body: Column(
        children: [
          Text( "State value: ${cc.state.someInfo}"),
          ElevatedButton(
            onPressed: (){
              cc.increment();
            },
            child: Text( "Increment counter" )
          )
        ],
      )
    );
  }
}
*/

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

void main(){
  runApp( myApp() );
}

TextStyle ts = TextStyle( fontSize: 30 );

class myApp extends StatelessWidget{
  myApp( {super.key} );
  @override
  Widget build( BuildContext context ){
    String title = "title";
    return MaterialApp(
      title: "MaterialApp",
      home: TopBloc( title:title ),
    );
  }
}

class someState {
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
  final String title ;
  TopBloc( {required this.title, super.key } );

  @override
  Widget build( BuildContext context ){
    return BlocProvider<someCubit>(
      create: (context)=>someCubit(),
      child: BlocBuilder<someCubit, someState>(
        builder: (context, state)=>HomePage( )
      ),
    );
  }
}


class HomePage extends StatelessWidget {
  final String title = "Route1";
  HomePage( { super.key } );

  @override
  Widget build( BuildContext context ){

    someCubit cc = BlocProvider.of<someCubit>( context );

    return Scaffold(
      appBar: AppBar( title: Text( title, style: ts ) ),
      body: Column(
        children: [
          Text( "${title} "),
          Text( "State value: ${cc.state.someData}" ),
          ElevatedButton(
            onPressed:(){
              cc.increment();
            },
            child: Text( "inc" )
          ),
          ElevatedButton(
            onPressed:(){
              Navigator.of( context ).push(
                MaterialPageRoute(
                  builder: (context)=> Route2( cc:cc )
                )
              );
            },
            child: Text( "go forward", style: ts )
          )
        ],
      )
    );
  }
}

class Route2 extends StatelessWidget{
  final String title = "Route2";
  final someCubit cc;
  Route2( {required this.cc, super.key} );

  @override
  Widget build( BuildContext context ){
    return BlocProvider<someCubit>.value(
      value: cc,
      child: BlocBuilder<someCubit, someState>(
        builder: ( context, state ){
          return Scaffold(
            appBar: AppBar( title: Text( title, style:ts ) ),
            body: Column(
              children: [
                Text( "${title}" ),
                Text( "${cc.state.someData}" ),
                ElevatedButton(
                  onPressed:(){
                    Navigator.of( context ).pop();
                  },
                  child: Text( "go back", style: ts )
                )
              ]
            )
          );
        }
      )
    );
  }

}