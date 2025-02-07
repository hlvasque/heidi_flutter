// Barrett Koster
// This is a finished Yahtzee roller.
// I am converting it to BLoC.

import "dart:math";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class SumState
{
  int sum;
  List<int> faces;

  SumState( this.sum, this.faces );
}
class SumCubit extends Cubit<SumState>
{
  SumCubit() : super( SumState(0,[1,2,3,4,5]) );

  // give new value for ONE of the face values on
  // the list.
  void update( int which, int f)
  { state.faces[which] = f;  // we are changing old state, sloppy
    int sum = 0;
    for ( int i=0; i<5; i++ )
    { sum += state.faces[i]; }
    emit(SumState(sum,state.faces)); 
  }
}

void main() 
{
  runApp(Yahtzee());
}

class Yahtzee extends StatelessWidget
{
  Yahtzee({super.key});

  @override
  Widget build( BuildContext context )
  { return BlocProvider<SumCubit>
    ( create: (context) => SumCubit(),
      child:  MaterialApp
      ( title: "yahtzeeBLoC - Barrett",
        home: YahtzeeHome(),
      ),
    );
  }
}

class YahtzeeHome extends StatelessWidget
{
  List<Dice> theDice = [Dice(0),Dice(1),Dice(2),Dice(3),Dice(4), ];
  @override
  Widget build( BuildContext context )
  { return Scaffold
    ( appBar: AppBar(title: const Text("yahtzeeBLoC")),
      body: BlocBuilder<SumCubit,SumState>
      ( builder: (context,sumState)
        { return Column 
          ( children:
            [ FloatingActionButton
              ( onPressed: () { rollAll(); },
                child: const Text("roll all",style:TextStyle(fontSize:30)),
              ),
              Text("total ${sumState.sum}",style:const TextStyle(fontSize:30)),
              Row( children: theDice, ),
            ]
          );
        },
      ),
    );
  }

  void rollAll()
  { for ( Dice d in theDice )
    { d.d1.roll(); }
  }
}

class DiceState
{
   int face; // number facing up when rolled
   bool hold; // true means do not change face when rolled

   DiceState( this.face, this.hold );
}
class DiceCubit extends Cubit<DiceState>
{
  DiceCubit() : super( DiceState(0,false) );

  void updateHold( bool h ){ emit(DiceState(state.face,h) ); }
  void updateFace(  int f ){ emit(DiceState(f,state.hold) ); }
}

// shows a box with dots and a 'hold' button
// debugging: and a 'roll' button
class Dice extends StatelessWidget
{ final int id;
  Dice(this.id);

  late Dice1 d1;
  Widget build( BuildContext context )
  { return BlocProvider<DiceCubit>
    ( create: (cotext) => DiceCubit(),
      child: BlocBuilder<DiceCubit,DiceState>
      ( builder: (context,state)
        { return d1=Dice1(id); },
      ),
    );
  }
}

class Dice1 extends StatelessWidget
{ final int id;
  Dice1(this.id);

  static final randy = Random();
  late BuildContext bc;
  Widget build( BuildContext context )
  { bc = context;
    List<Dot> dots = [];
    DiceCubit dCubit = BlocProvider.of<DiceCubit>(context);
    DiceState dState = dCubit.state;
    int face = dState.face;
    bool holding = dState.hold;
    if ( face>1 ) // upper left and lower right
    { dots.add( Dot(top:10,left:20) );
      dots.add( Dot(top:70, left:70) );
    }
    if ( face>3 ) // other corners
    { dots.add( Dot(top:10,left:70) );
      dots.add( Dot(top:70, left:20) );
    }
    if ( face==6 ) // middle side dots
    { dots.add( Dot(top:40,left:20) );
      dots.add( Dot(top:40, left:70) );
    }
    if ( face==1 || face==3 || face==5 ) // center dot
    { dots.add( Dot(top:40,left:45) ); 
    }

    // the box with dots and two buttons
    return Column
    ( children: 
      [ Container
        ( decoration: BoxDecoration
          ( border: Border.all( width:2, ) ,
            color: (holding? Colors.pink: Colors.white),
          ),
          height: 100, width: 100, 
          child: Stack( children:dots, ),
        ),
        FloatingActionButton
        ( onPressed: (){ dCubit.updateHold(!dState.hold); },
          child: const Text("hold"),
        ),
        // just for debugging
        FloatingActionButton
        ( onPressed: () { dCubit.updateFace( roll() ); },
          child: Text("roll"),
        ),
      ],
    );
  }

  // if not on hold, find a new random number 1-6
  // update the cubit for the state of THIS Dice.
  // update the SumCubit for the whole app.
  int roll()
  { DiceCubit dCubit = BlocProvider.of<DiceCubit>(bc);
    DiceState dState = dCubit.state;
    int f = dState.face;
    if ( !dState.hold )
    { f = randy.nextInt(6)+1; 
      dCubit.updateFace(f);
    }

    SumCubit sCubit = BlocProvider.of<SumCubit>(bc);
    sCubit.update(id,f);
    return f;
  }
}

// is one dot on the (showing) face of a Dice (die).
// A Dot knows where it is suppose to be because it 
// extends a Positioned.  The coordinates have to be
// named in the constructor call.
class Dot extends Positioned
{
  Dot(  {super.top, super.left } )
  : super
    ( child: Container
      ( height: 10, width: 10,
        decoration: BoxDecoration
        ( color: Colors.black,
          shape: BoxShape.circle,
        ),
      ),
    );
}