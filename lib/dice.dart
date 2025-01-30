import "package:flutter/material.dart";
import "dart:math";

//Heidi Vasquez
void main(){
  runApp( myMain() );
}

class myMain extends StatelessWidget{
  myMain( {super.key} );

  @override
  Widget build( BuildContext context ){
    return MaterialApp(
      title: "myMain",
      home: myMainHome(),
    );
  }
}

class myMainHome extends StatefulWidget {
  @override
  State<myMainHome> createState()=> myMainHomeState();
}

class myMainHomeState extends State<myMainHome>{
  int totalInFist = 6 + 5 + 4 + 3 + 2 + 1;

  void updateTotalInFist( int oldVal, int newVal ){
    setState(() {
      totalInFist-= oldVal;
      totalInFist += newVal;
    });
  }
  @override
  Widget build( BuildContext context ){
    return Scaffold (
      appBar: AppBar( title: const Text("myMain" ) ),
      body: Row(
        children: [
          Dice( 1, updateTotalInFist ), Dice( 2, updateTotalInFist ), Dice( 3, updateTotalInFist ), Dice( 4, updateTotalInFist ), Dice( 5, updateTotalInFist), Dice( 6, updateTotalInFist ),
          Text( "Total in Fist: $totalInFist" )
        ],
      )
    );
  }
}

class Dice extends StatefulWidget {
  //Dice needs to extend StatefulWidget bc some of its variables will change
  int face;
  final Function( int, int ) updateTotalInFist;
  Random myRand = Random();
  Dice( this.face, this.updateTotalInFist );
  @override
  State<Dice> createState() => DiceState( face );
}

class DiceState extends State<Dice>{
  int face = 6;
  Random myRand = Random();

  DiceState( this.face );


  Widget build( BuildContext context ){
    return Column(
    children: [
      Container
      (
      decoration: BoxDecoration
          ( border: Border.all( width: 1, ) ),
          height: 100,
          width: 100,
          child: Stack (
            children: [

              [1].contains( face )?
                  Stack(
                    children: [
                      Dot( 40, 40 )
                    ],
                  ) : Text("")
              ,
              [2].contains( face )?
                  Stack(
                    children: [
                      Dot( 10, 10 ),
                      Dot( 70, 70 )
                    ],
                  ): Text(""),
              [3].contains( face )?
                  Stack(
                    children: [
                      Dot(40, 40 ),
                      Dot( 10, 10 ),
                      Dot( 70, 70 )
                    ],
                  ): Text(""),
              [4].contains( face )?
                  Stack(
                    children: [
                      Dot( 10, 10 ),
                      Dot( 70, 70 ),
                      Dot( 10, 70 ),
                      Dot( 70, 10 )
                    ],
                  ): Text(""),
              [5].contains( face )?
                  Stack(
                    children: [
                      Dot( 40, 40 ),
                      Dot( 10, 10 ),
                      Dot( 70, 70 ),
                      Dot( 10, 70 ),
                      Dot( 70, 10 ),
                    ],
                  ): Text( "" ),
              [6].contains(face )?
                  Stack(
                    children: [
                      Dot( 10, 10 ),
                      Dot( 70, 70 ),
                      Dot( 10, 70 ),
                      Dot( 70, 10 ),
                      Dot( 10, 40 ),
                      Dot( 70, 40 )
                    ],
                  ): Text( "" ),
            ],
          )
      ),
      rollButton()
    ]
    );
  }

  //reset the face to a random integer generated from 1- 6
  FloatingActionButton rollButton()
  { int temp = face;
    return FloatingActionButton
    ( onPressed: ()
  { setState
    ( ()

      //generates a rand int from 0 -5 and adds 1 so we get numbers from 1-6
      {
        face = myRand.nextInt( 6 ) + 1;
      },

  );
  widget.updateTotalInFist( temp, face );
  },
    child: Text("roll"),
  );
  }

}

class Dot extends Positioned {
  final double x;
  final double y;

  Dot( this.x, this.y )
  : super
      (
      left: x, top: y,
      child: Container
        (
        //set the shape of the dot
        height: 10, width: 10,
        decoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle
        ),
      )
    );


}

