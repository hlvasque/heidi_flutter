// main.dart
// Barrett Koster 2025

// This app is a countdown to the next US presidential
// inauguration.


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MsgState
{
  String msg;
  MsgState( this.msg );
}

class MsgCubit extends Cubit<MsgState>
{
  MsgCubit() :super( MsgState("until") );

  update( String s ) { emit( MsgState(s) ); }
}

void main()
{ runApp(const Until1());
}

class Until1 extends StatelessWidget
{ const Until1({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp
    (
      title: 'until',
      home: BlocProvider<MsgCubit>
      ( create: (context) => MsgCubit(),
        child: BlocBuilder<MsgCubit,MsgState>
        ( builder: (context,state) => Until2(),
        ),
      ),
    );
  }
}

class Until2 extends StatelessWidget
{
  Until2({super.key});

  // whatTime() figures out how long it it from now until
  // 2029 Jan 20 noon in DC.
  // sets msg to that time after a delay of 1 s.
  // If called inside the BLoC that msg uses ... will create
  // infinite call-back loop.  
  Future<void> whatTime( BuildContext context ) async
  {
    DateTime now = DateTime.now();
    DateTime inaug = DateTime.parse("2029-01-20 17:00:00Z");

    final diff = inaug.difference(now);

    final ts = diff.inSeconds;
    final tm = diff.inMinutes;
    final s = ts - tm * 60;
    final th = diff.inHours;
    final m = tm - th * 60;
    final td = diff.inDays;
    final h = th - td*24;

    final msg = "${td} days\n$h:$m:$s";

    await Future.delayed( const Duration(seconds:1) ); 

    MsgCubit mc = BlocProvider.of<MsgCubit>(context);
    mc.update(msg);

    // return diff;
  }

  @override
  Widget build(BuildContext context) 
  { whatTime(context);
    MsgCubit mc = BlocProvider.of<MsgCubit>(context);

    return Scaffold
    ( // appBar: AppBar( title: Text("until"),),
      body: Center
      ( child: Text(mc.state.msg, style:TextStyle(fontSize:30) ),),
    );
  }
}
