// dice3.dart
// Barrett Koster
// Now we make dice with a roll button, and a hold button.

import "dart:math";
import "package:flutter/material.dart";

void main() // 23
{
  runApp(Yahtzee());
}

class Yahtzee extends StatelessWidget
{
  Yahtzee({super.key});

  @override
  Widget build( BuildContext context )
  { return MaterialApp
    ( title: "yahtzee",
      home: YahtzeeHome(),
    );
  }
}

class YahtzeeHome extends StatefulWidget
{
  @override
  State<YahtzeeHome> createState() => YahtzeeHomeState();
}
    
class YahtzeeHomeState extends State<YahtzeeHome>
{
  @override
  Widget build( BuildContext context )
  { return Scaffold
    ( appBar: AppBar(title: const Text("yahtzee")),
      body: Row
      ( children:
        [ Dice(1), Dice(2),Dice(3),Dice(4),Dice(5),Dice(6),
        ]
      ),
    );
  }
}

class Dice extends StatefulWidget
{ int face;
  Dice(this.face);

  @override
  State<Dice> createState() => DiceState(face);
}

class DiceState extends State<Dice> 
{
  int face = 6;
  bool hold = false;
  DiceState(this.face);
  Random randy = Random();

  Widget build( BuildContext context )
  { return Column
    ( children: 
      [ Container
        ( decoration: BoxDecoration
          ( border: Border.all( width:1, ) ,
            color: hold? Colors.pink: Colors.white,
          ),
          height: 100,
          width: 100,
          child: Stack
          ( children: 
            [ ([1,3,5].contains(face)? Dot(40,40): Text("") ), // center
              ([2,3,4,5,6].contains(face)? Dot(10,10): Text("") ),
              ([2,3,4,5,6].contains(face)? Dot(70,70): Text("") ),
              ([4,5,6].contains(face)? Dot(10,70): Text("") ),
              ([4,5,6].contains(face)? Dot(70,10): Text("") ),
              ([6].contains(face)? Dot(10,40): Text("") ),
              ([6].contains(face)? Dot(70,40): Text("") ),
              //Dot(50, 70),
            ],
          ),
        ),
        rollButton(),
        holdButton(),
      ],
    );
  }

  FloatingActionButton rollButton()
  { return FloatingActionButton
    ( onPressed: ()
      { setState
        ( ()
          { if (!hold) { face = randy.nextInt(6)+1; }
          } 
        ); 
      },
      child: Text("roll"),
    );
  }
  FloatingActionButton holdButton()
  { return FloatingActionButton
    ( onPressed: () { setState( () { hold = !hold; }  );  },
      child: Text("hold"),
    );
  }
}

class Dot extends Positioned
{
  final double x;
  final double y;

  Dot( this.x, this.y ) 
  : super
  ( left: x, top: y,
    child: Container
    ( height: 10, width: 10,
      decoration: BoxDecoration
      ( color: Colors.black,
        shape: BoxShape.circle,
      ),
    ),
  );
}
