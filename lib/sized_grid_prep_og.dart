import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

//create a class to store the size of the grid
//the initial size is 4 * 3
class Box1 {
  int gridWidth;  // Number of columns
  int gridHeight; // Number of rows

  Box1({required this.gridWidth, required this.gridHeight});
}

//this is a container around the grid
class Boxy extends StatelessWidget {
  final double width;
  final double height;

  Boxy({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.0),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(),
        ),
        child: Center(child: Text("x")),
      ),
    );
  }
}

//create a cubit class that can update the grid size
class BoxCubit extends Cubit<Box1> {
  BoxCubit() : super(Box1(gridWidth: 4, gridHeight: 3));

  //update the grid size
  void updateGridSize(int newGridWidth, int newGridHeight) {
    emit(Box1(gridWidth: newGridWidth, gridHeight: newGridHeight));
  }
  //increment width by 1
  void incrementWidth() {
    emit(Box1(gridWidth:state.gridWidth + 1, gridHeight:state.gridHeight ) );
  }

  //increment height by 1
  void incrementHeight() {
    emit(Box1(gridWidth:state.gridWidth, gridHeight:state.gridHeight + 1) );
  }
}

void main() {
  runApp(SG());
}


class SG extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BoxCubit(),
      child: MaterialApp(
        title: "Sized Grid Prep",
        home: SG1(),
      ),
    );
  }
}

class SG1 extends StatefulWidget {
  @override
  _SG1State createState() => _SG1State();
}


class _SG1State extends State<SG1> {
  final TextEditingController _gridWidthController = TextEditingController();
  final TextEditingController _gridHeightController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    //get the current state of the grid from BoxCubit
    //(grab it's width and height)
    Box1 boxDimensions = context.watch<BoxCubit>().state;

    //re-crate the grid dynamically based on the current state (number of rows/columns)
    List<Widget> rows = [];
    for (int i = 0; i < boxDimensions.gridHeight; i++) {
      List<Widget> columns = [];
      for (int j = 0; j < boxDimensions.gridWidth; j++) {
        columns.add(Boxy(width: 40.0, height: 40.0));
      }
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: columns,
      ));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Sized Grid")),
      body: Column(
        children: [
          Text("before the grid"),
          Column(children: rows),
          Text("after the grid"),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Grid Width (number of columns):"),
                TextField(
                  controller: _gridWidthController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: "enter grid width"),
                ),
                Text("Grid Height (number of rows):"),
                TextField(
                  controller: _gridHeightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: "enter grid height"),
                ),
                ElevatedButton(
                  onPressed: () {
                    //parse the new width/height from the input
                    int newGridWidth = int.tryParse(_gridWidthController.text) ?? boxDimensions.gridWidth;
                    int newGridHeight = int.tryParse(_gridHeightController.text) ?? boxDimensions.gridHeight;

                    //update the cubit state (width & height)
                    context.read<BoxCubit>().updateGridSize(newGridWidth, newGridHeight);
                  },
                  child: Text("Update Grid Size (Number of Boxes)"),
                ),
                ElevatedButton(
                  onPressed: (){
                    context.read<BoxCubit>().incrementHeight();
                  },
                  child: Text( "Inc. Height" )
                ),
                ElevatedButton(onPressed: (){
                  context.read<BoxCubit>().incrementWidth();
                }, child: Text( "Inc. Width"))
              ],
            ),
          ),
        ],
      ),

    );
  }
}
