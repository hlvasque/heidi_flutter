import "package:flutter/material.dart";

void main(){
  runApp( Dice() );
}

class Dice extends StatelessWidget {
  Dice({ super.key } );

  @override
  Widget build( BuildContext context ) {
    return MaterialApp
      (
        title: "Dice",
      home: DiceHome(),
    );
  }
}

class DiceHome extends StatefulWidget{
  @override
  State<DiceHome> createState() => DiceHomeState();
}

class DiceHomeState extends State<DiceHome>{
  @override
  Widget build( BuildContext context )
  {
    return Scaffold
      (

    );
  }
}