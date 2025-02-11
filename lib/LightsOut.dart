//heidi vasquez
// Lights Out
// let user enter N and create a row of N lights
// lights are randomly on/off to start
// clicking on a light flips that one AND its 2 neighbors
// goal: get all of the lights to go out

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

//class that keeps track of the state of each light (on/off)
class IndividualBox {
  bool lightsOn;

  IndividualBox({required this.lightsOn});
}

//cubit class to update the state of each light
class IndividualBoxCubit extends Cubit<IndividualBox> {
  IndividualBoxCubit() : super(IndividualBox(lightsOn: false));

  //flip the light's state
  void flipLights() {
    emit(IndividualBox(lightsOn: !state.lightsOn));
  }
}

void main() {
  runApp(SG());
}

class SG extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Lights Out Game",
      home: SG1(),
    );
  }
}

class SG1 extends StatefulWidget {
  @override
  _SG1State createState() => _SG1State();
}



class _SG1State extends State<SG1> {
  final TextEditingController _columnController = TextEditingController();
  int numColumns = 5; //let's set default to 5?
  final random = Random(); //use rand to randomly initialize lights to on/off state

  //create a list to hold a list of cubits so we can access them later
  List<IndividualBoxCubit> lightCubits = [];

  @override
  Widget build(BuildContext context) {

    List<Widget> lightsRow = [];

    //generate the list of cubits here
    lightCubits = List.generate( numColumns, (index) => IndividualBoxCubit() );
    //randomly initialize their on/off state
    final random = Random();

    for (int i = 0; i < lightCubits.length; i++) {
      final random = Random();
      if ( random.nextInt( lightCubits.length ) % 2 == 0 ) {
        lightCubits[i].flipLights(); //turn light on/off
      }
    }

    for (int i = 0; i < numColumns; i++) {
      //create a blocProvider for each light

      lightsRow.add(
        BlocProvider(
          create: (context) => lightCubits[i],
          child: BlocBuilder<IndividualBoxCubit, IndividualBox>(
            builder: (context, lightState) {

              //when you click on a light
              return GestureDetector(
                onTap: () {
                  //flip the light
                  context.read<IndividualBoxCubit>().flipLights();

                  //check if it has a left neighbor
                  //(if so, flip its light too)
                  if ( i > 0 ) {
                    lightCubits[i - 1].flipLights();
                  }

                  //check if it has a right neighbor
                  //(if so, flip its light too)
                  if ( i < numColumns - 1 ) {
                    lightCubits[i + 1].flipLights();
                  }
                },
                child: Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: lightState.lightsOn ? Colors.yellow : Colors.brown,
                      border: Border.all(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("lights out- heidi"),
      ),
      body: Center(
        child: Column(
          children: [
            //input to change number of columns/lights
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _columnController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Number of Columns',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newColumns = int.tryParse(_columnController.text);
                //only update num of cols if greater than or equal to 3 and less than or equal to 15
                if (newColumns != null && newColumns >= 3 && newColumns <= 15 ) {
                  setState(() {
                    numColumns = newColumns; //update cols
                  });
                }
              },
              child: Text("update num lights (must be between 3 and 15)"),
            ),
            //display row of lights
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: lightsRow,
            ),
          ],
        ),
      ),
    );
  }
}
