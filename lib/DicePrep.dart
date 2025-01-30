// DicePrep.dart

// Heidi Vasquez

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
        [ const Text
          ( "font styles", 
            style: TextStyle
            ( fontSize: 35,
              color: Colors.orange,
            ) 
          ),
          Spacer(flex:1),
          Text
          ( "line 2", 
            style: TextStyle
            ( fontWeight: FontWeight.bold,
              fontSize: 30,
            ),
          ),
          Spacer(flex:1),
          Container
          ( decoration: BoxDecoration
            ( color: Colors.pink,
              border: Border.all
              ( width:8,
              )
            ),
            child: Text
            ( "in box",style:TextStyle
              ( fontSize: 40)
            ),
          ),
          Container
          ( decoration: BoxDecoration
            ( border: Border.all( width:1, ) ),
            height: 100,
            width: 100,
            child: Stack
            ( children: 
              [ Positioned
                ( left: 10,
                  top: 40,
                  child: Text("hi"),
                ),
                Text("lo"),
                Positioned
                ( left: 80, top: 70,
                  child: Container
                  ( height: 10, width: 10,
                    decoration: BoxDecoration
                    ( color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  )
                ),
              ],
            ),
          ),
        ]
      ),
    );
  }
}

