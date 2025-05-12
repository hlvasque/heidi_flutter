// Barrett Koster 2024
// demo of natural threads ... increment widgets 
// running at their own pace.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main()
{ runApp(const Race());
}

class RunnerState
{ double miles;
  RunnerState( this.miles );
}
class RunnerCubit extends Cubit<RunnerState>
{
  RunnerCubit() : super( RunnerState(0) );

  go1mile() { emit(RunnerState(state.miles+1) ); }
}

class Race extends StatelessWidget 
{ const Race({super.key});

  @override
  Widget build(BuildContext context)
  { return const MaterialApp
    ( title: 'Race',
      home:  RaceHome(),
    );
  }
}

class RaceHome extends StatelessWidget 
{ const RaceHome({super.key});

  @override
  Widget build(BuildContext context)
  { return Scaffold
    (
      appBar: AppBar( title: Text("Race"),  ),
      body: Row
      ( children:
        [ Racer("bob"), Racer("mary"), Racer("jane")],
      ),
    );
  }
}

// Each racer has its own state, the number of miles
// it has gone.  Each Racer is a box with a number that goes
// up as it runs.
class Racer extends StatelessWidget
{ final String name;
  Racer(this.name, {super.key});

  @override
  Widget build( BuildContext context )
  { 
    return BlocProvider<RunnerCubit>
    ( create: (context) => RunnerCubit(),
      child: BlocBuilder<RunnerCubit,RunnerState>
      ( builder: (context,state)
        { return Racer1(name); },
      ),
    );
  }
}

class Racer1 extends StatelessWidget
{ final String name;
  Racer1(this.name,{super.key});
  static final Random randy = Random();
  
  @override
  Widget build( BuildContext context )
  { RunnerCubit rc = BlocProvider.of<RunnerCubit>(context);
    running(context); // do NOT wait for this to finish.
    return Column
    ( children:
      [ BB(name),
        BB( "${rc.state.miles}" ),
      ],
    );
  }

  // running waits a random amount of time and then increments
  // the miles in state.
  // note: this gets called every time Racer1 (re) builds, and 
  // the 'emit()' in go1mile() triggers a rebuild (so it is an
  // infinite loop.
  void running(BuildContext bc) async
  { RunnerCubit rc = BlocProvider.of<RunnerCubit>(bc);
    int howMuch = randy.nextInt(500) + 100;
    await Future.delayed( Duration(milliseconds:howMuch) );
    rc.go1mile();
  }
}

// BB is a box with a border.
class BB extends Container
{
  BB( String s ) : super
  ( decoration: BoxDecoration
    ( border: Border.all(width:2),),
    width:100, height:50,
    child: Text(s, style: TextStyle(fontSize: 20) ),
  );
}