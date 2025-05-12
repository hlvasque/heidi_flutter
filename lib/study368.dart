import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'dart:io';
import 'dart:convert';

// TextStyle declaration
TextStyle ts = TextStyle(fontSize: 30);

// Main function to run the app
void main() {
  runApp(MyApp());
}

// Some variables and print statement
/*int x = 6;
String bob = "x is $x";
print("sqrt(x) is ${sqrt(x)}");*/

// MyApp class, which is a StatelessWidget
class MyApp extends StatelessWidget {
  MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    String title = "Some Program";
    return MaterialApp(
      title: "Some Program",
      home: TopBloc(title: title),
    );
  }
}

// BLoC state and cubit classes
class SomeState {
  int someInfo;
  SomeState(this.someInfo);
}

class SomeCubit extends Cubit<SomeState> {
  SomeCubit() : super(SomeState(0));
  void update(int x) {
    emit(SomeState(x));
  }
}

// TopBloc class, which is a StatelessWidget that provides the BLoC
class TopBloc extends StatelessWidget {
  final String title;
  TopBloc({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SomeCubit>(
      create: (context) => SomeCubit(),
      child: BlocBuilder<SomeCubit, SomeState>(
        builder: (context, state) => HomePage(title: title, state: state),
      ),
    );
  }
}

// HomePage class, which displays UI and interacts with the BLoC
class HomePage extends StatelessWidget {
  final String title;
  final SomeState state;

  HomePage({required this.title, required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    SomeCubit cc = BlocProvider.of<SomeCubit>(context);
    return Scaffold(
      appBar: AppBar(title: Text(title, style: ts)),
      body: Column(
        children: [
          Text("State value: ${state.someInfo}", style: TextStyle(fontSize: 30)),
          ElevatedButton(
            onPressed: () {
              cc.update(state.someInfo + 1); // Increment the state
            },
            child: Text("Increment State"),
          ),
          SizedBox(
            height: 50,
            width: 200,
            child: TextField(
            decoration: InputDecoration(hintText: "Type something here..."),
              style: ts,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              does_something();
            },
            child: Text("push me"),
          ),
        ],
      ),
    );
  }
}

// Placeholder function for ElevatedButton
void does_something() {
print("Button pressed");
}

// File handling code (Note: This will only work with a valid file path)
/*File dataFile = File("someDirectory/someFile.ext");
// String contents = dataFile.readAsStringSync();
List<String> lines = dataFile.readAsLinesSync(encoding: utf8);
File fodder = File("filePath");
fodder.writeAsStringSync("put this in the file");

// Dummy route for navigation (you can replace it with your own widget)
class Route2 extends StatelessWidget {
final String title;
final SomeCubit cc;

Route2({required this.title, required this.cc});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: Text(title)),
body: Center(child: Text("Route2 page")),
);
}
}

// Navigation code (will work if Route2 is defined correctly)
Navigator.of(context).push(
MaterialPageRoute(
builder: (context) => Route2(title: 'New Page', cc: SomeCubit()),
),
);
Navigator.of(context).pop();

// Schneiderman's 8 principles
// 1. Consistency
// 2. Usability
// 3. Feedback
// 4. Closure
// 5. Prevent errors
// 6. Allow backup
// 7. Users in control
// 8. Reduce short-term memory load*/
