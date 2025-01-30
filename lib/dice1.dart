// dice1.dart
// Barrett Koster
// step 1 of converting DicePrep into what we want.
// ... get a Dot working in a square, clear out the rest

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
      body: Column
      ( children:
        [ Container
          ( decoration: BoxDecoration
            ( border: Border.all( width:1, ) ),
            height: 100,
            width: 100,
            child: Stack
            ( children: 
              [ Dot(10,10),
                Dot(50, 70),
              ],
            ),
          ),
        ]
      ),
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
