//Heidi Vasquez
import 'dart:ffi';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "robot",
      home: MyAppHome(),
    );
  }
}

class MyAppHome extends StatefulWidget {
  const MyAppHome({super.key});

  @override
  MyAppHomeState createState() => MyAppHomeState();
}

class MyAppHomeState extends State<MyAppHome> {
  int chosenRow = 1;
  int chosenCol = 1;

  int box1Row = 2;
  int box1Col = 2;

  String stringToShow = "Move Box1 into Goal1.";

  List<int> roadBlock1 = [3, 4];
  List<int> goal1 = [2, 1 ];

  void oneRowUp() {
    setState(() {
      if (chosenRow > 1 ) {
        if( (box1Col != chosenCol || chosenRow-1 != box1Row) && !(chosenRow-1==roadBlock1[0] && chosenCol==roadBlock1[1] ) ) {
          chosenRow --;
        }
        else if( box1Row > 1 && box1Row == chosenRow-1 && box1Col == chosenCol && !(box1Row-1==roadBlock1[0] && chosenCol==roadBlock1[1] ) ){
          box1Row--;
          chosenRow--;
        }
        if( box1Row == goal1[0] && box1Col == goal1[1] ){
          stringToShow = "Successfully placed Box1 into Goal1!";
        }
        else {
          stringToShow = "Move Box1 into Goal1.";
        }
      }
    });
  }

  void oneRowDown(){
    setState(() {
      if( chosenRow < 4 ){
        if( ( box1Col != chosenCol || chosenRow+1 != box1Row ) && !(chosenRow+1==roadBlock1[0] && chosenCol==roadBlock1[1] ) ){
          chosenRow ++;
        }
        else if( box1Row < 4 && box1Row == chosenRow+1 && box1Col == chosenCol && !(box1Row+1==roadBlock1[0] && chosenCol==roadBlock1[1] ) ){
          box1Row ++;
          chosenRow ++;
        }
        if( box1Row == goal1[0] && box1Col == goal1[1] ){
          stringToShow = "Successfully placed Box1 into Goal1!";
        }
        else {
          stringToShow = "Move Box1 into Goal1.";
        }
      }
    });
  }

  void oneColLeft() {
    setState(() {

      if (chosenCol > 1) {
        if( ( box1Row != chosenRow || box1Col != chosenCol - 1 ) && !(chosenCol-1==roadBlock1[1] && chosenRow==roadBlock1[0] ) ){
          chosenCol --;
        }
        else if( box1Col > 1 && (box1Col == chosenCol-1) && box1Row == chosenRow && !(box1Col-1==roadBlock1[1] && chosenRow==roadBlock1[0] ) ) {
          chosenCol --;
          box1Col --;
        }
        if( box1Row == goal1[0] && box1Col == goal1[1] ){
          stringToShow = "Successfully placed Box1 into Goal1!";
        }
        else {
          stringToShow = "Move Box1 into Goal1.";
        }
      }
    });
  }

    void oneColRight(){
      setState(() {
        if( chosenCol < 4 ){
          if( (box1Row != chosenRow || box1Col != chosenCol + 1) && !(chosenCol+1==roadBlock1[1] && chosenRow==roadBlock1[0] ) ){
            chosenCol ++;
          }
          else if( box1Col < 4 && (box1Col == chosenCol+1) && box1Row == chosenRow && !(box1Col+1==roadBlock1[1] && chosenRow==roadBlock1[0] )  ){
            chosenCol ++;
            box1Col ++;
          }
          if( box1Row == goal1[0] && box1Col == goal1[1] ){
            stringToShow = "Successfully placed Box1 into Goal1!";
          }
          else {
            stringToShow = "Move Box1 into Goal1.";
          }
        }
      });
    }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Robot Lab")),
      body: Column(

        children: [
          Text( stringToShow, style: TextStyle( fontSize: 20 )  ),
          // Build grid directly
          Column(
            children: List.generate(6, (row) {
              return Row(
                children: List.generate(6, (col) {
                  return Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 2,
                        color:  row == 0 || row == 5 || col == 0 || col == 5 ? Color(0xfff00000 ): Color( 0xff000000 ),
                      ),
                    ),
                    child: (row == chosenRow && col == chosenCol)
                        ? const Text("R", style: TextStyle(fontSize: 40, color:Colors.blue))
                        : (row == box1Row && col == box1Col ? Text("B1", style: TextStyle(fontSize: 40, color: Colors.brown) ) : (row == roadBlock1[0] && col == roadBlock1[1] ? Text("block"): (row == goal1[0] && col == goal1[1] ? Text( "Goal 1" ): const Text("")  )  ) ) ,
                  );
                }),
              );
            }),
          ),
          Row(
            children: [
              FloatingActionButton(
                onPressed: oneRowUp,
                child: const Text("Up"),
              )
              ,
              FloatingActionButton(onPressed: oneRowDown,
                  child: Text( "Down" )
              ),
              FloatingActionButton(
                onPressed: oneColLeft,
                child: Text( "Left" ),
              ),
              FloatingActionButton(
                onPressed: oneColRight,
                child: Text( "Right" ),
              ),
            ]

          ),
        ],
      ),
    );
  }
}