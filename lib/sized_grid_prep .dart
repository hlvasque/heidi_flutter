// sized_grid_prep_og.dart
// Barrett Koster  2025 
// lab
// let user enter 2D grid size, make grid that size

import "package:flutter/material.dart";

void main()
{ runApp(SG()); }

class SG extends StatelessWidget
{
  SG({super.key});

  Widget build( BuildContext context )
  {
    return MaterialApp
    ( title: "sized grid prep",
      home: SG1(),
    );
  }
}

class SG1 extends StatelessWidget
{
  SG1({super.key});

  Widget build( BuildContext context )
  { 
    int width = 4;
    int height = 3;

    Row theGrid = Row(children:[]);
    for ( int i=0; i<width; i++ )
    { Column c = Column(children:[]);
      for ( int j=0; j<height; j++ )
      { c.children.add( Boxy(40,40)  );
      }
      theGrid.children.add(c);
    }

    return Scaffold
    ( appBar: AppBar( title: Text("sized grid") ),
      body: Column
      ( children:
        [ Text("before the grid"),
          theGrid,
          Text("after the grid"),
        ],
      ),
    );
  }
}

class Boxy extends Padding
{
  final double width;
  final double height;
  Boxy( this.width,this.height ) 
  : super
    ( padding: EdgeInsets.all(4.0),
      child: Container
      ( width: width, height: height,
        decoration: BoxDecoration
        ( border: Border.all(), ),
        child: Text("x"),
      ),
    );
}
