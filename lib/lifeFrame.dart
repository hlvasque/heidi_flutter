// life.dart
// Barrett Koster 2025 (with simple animation)
// demo of implicit animation.

import "dart:math";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class Coords {
  double x, y;
  Coords(this.x, this.y);
}

//keeps track of grid state
class DragState {
  List<List<bool>> world;

  DragState(this.world);

  DragState.first() : world = init();

  static List<List<bool>> init() {
    List<List<bool>> grid = [];
    for (int i = 0; i < 20; i++) {
      List<bool> row = [];
      for (int j = 0; j < 20; j++) {
        row.add(Random().nextInt(10) > 6 ? true : false);
      }
      grid.add(row);
    }
    return grid;
  }

  //simple animation: invert cells in a ripple pattern
  List<List<bool>> nextFrame() {
    List<List<bool>> newWorld = List.generate(
      world.length,
          (i) => List.generate(world[0].length, (j) => world[i][j]),
    );

    //get middle of grid
    int midX = world.length ~/ 2;
    int midY = world[0].length ~/ 2;

    //update a few rand cells
    for (int i = 0; i < world.length; i++) {

      for (int j = 0; j < world[0].length; j++ ) {
        //calc distance from center
        double distance = sqrt(pow(i - midX, 2) + pow(j - midY, 2));
        //create ripple effect based on distance
        if (distance > Random().nextInt(10) && Random().nextBool()) {
          newWorld[i][j] = !world[i][j];

        }
      }
    }

    return newWorld;
  }
}

class DragCubit extends Cubit<DragState> {
  DragCubit() : super(DragState.first());

  void update() {
    List<List<bool>> nextGen = state.nextFrame();
    emit(DragState(nextGen));
  }

  /*void reset() {
    emit(DragState.first());
  }*/

}

void main() {
  runApp(const Dragger());
}

class Dragger extends StatelessWidget {
  const Dragger({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'life lab',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider<DragCubit>(
        create: (context) => DragCubit(),
        child: BlocBuilder<DragCubit, DragState>(
          builder: (context, state) {
            return Dragger2();
          },
        ),
      ),
    );
  }
}

void mover(BuildContext context) async {
  DragCubit dg = BlocProvider.of<DragCubit>(context);

  // Update the grid every second
  await Future.delayed(const Duration(milliseconds: 300));
  dg.update();
}

class Dragger2 extends StatelessWidget {
  Dragger2({super.key});

  @override
  Widget build(BuildContext context) {
    DragCubit dg = BlocProvider.of<DragCubit>(context);

    //build grid with Text widgets
    List<Widget> rows = [];
    for (List<bool> row in dg.state.world) {
      List<Widget> cells = [];
      for (bool cell in row) {
        cells.add(
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 15,
            height: 15,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: cell ? Colors.blue : Colors.white,
              border: Border.all(color: Colors.grey, width: 1),
            ),
          ),
        );
      }
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: cells,
      ));
    }

     //the next frame
    mover(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('life lab'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(width: 2),
              ),
              child: Column(
                children: rows,
              ),
            ),
            /*const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => dg.reset(),
              chi\ld: const Text('Reset'),
            ),*/
          ],
        ),
      ),
    );
  }
}