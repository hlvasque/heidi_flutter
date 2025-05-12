// Barrett Koster
// keyboard demo

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bb.dart';

import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';

class SwipeState
{
  String direction;
  // bool showit = false;
  SwipeState( this.direction );
}
class SwipeCubit extends Cubit<SwipeState>
{
  SwipeCubit() : super( SwipeState("none") );
  set( String s ) { emit( SwipeState(s) ); }
}

void main() async
{ runApp(const SD());

}

class SD extends StatelessWidget 
{ const SD({super.key});
  final title = "Swipe Demo";

  @override
  Widget build(BuildContext context) 
  { return  MaterialApp
    ( 
      title: title,
      home: Scaffold
      ( appBar: AppBar( title: BB(title) ),
        body: BlocProvider<SwipeCubit>
        ( create: (context) => SwipeCubit(),
          child: BlocBuilder<SwipeCubit,SwipeState>
          ( builder: (context,state)
            { return SD1(); },
          ),
        ),
      ),
    );
  }
}

class SD1 extends StatelessWidget 
{ SD1({super.key});
 
  @override
  Widget build(BuildContext context)
  { SwipeCubit sc = BlocProvider.of<SwipeCubit>(context);
    return SwipeDetector
    ( onSwipeUp   : (_){ sc.set("up"); },
      onSwipeDown : (_){ sc.set("down"); },
      onSwipeLeft : (_){ sc.set("left"); },
      onSwipeRight: (_){ sc.set("right"); },
      child: Column
      ( children:
        [ Container
          ( width:500, height:500, 
            // child: BB(sc.state.direction),
            child: Text(sc.state.direction, style: TextStyle(fontSize:100) ),
          ),

        ],
      ),
    );
  }
}
