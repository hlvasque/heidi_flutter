// file_stuff.dart
// Barrett Koster
// This demos some basic file io in flutter.

import "dart:io";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:path_provider/path_provider.dart";
// cd to the project directory
// > flutter pub add path_provider

void main() 
{ runApp( FileStuff () );
}

class FileStuff extends StatelessWidget
{
  FileStuff({super.key});

  Widget build( BuildContext context )
  { return MaterialApp
    ( title: "file stuff - barrett",
      home: FileStuffHome(),
    );
  }
}

class FileStuffHome extends StatelessWidget
{
  FileStuffHome({super.key});

  @override
  Widget build( BuildContext context ) 
  { 
    Future<String> contents = readFile();
    writeFile("hi there");
    return Scaffold
    ( appBar: AppBar( title: Text("file stuff - barrett") ),
      body: Column
      ( children:
        [ FutureBuilder
          ( future: contents,
            builder: (context, snapshot ) 
            { if ( snapshot.connectionState == ConnectionState.done )
              { return Text(snapshot.data!); }
              else
              { return Text("loading ... "); }
            }
          ),
        ],
      ),
    );
  }

  Future<String> whereAmI() async
  {
    Directory mainDir = await getApplicationDocumentsDirectory();
    String mainDirPath = mainDir.path;
    // String mainDirPath = "/Users/bkoster/Documents/courses/USC/368/shared";
    print("mainDirPath is $mainDirPath");
    return mainDirPath;
  }
  
  Future<String> readFile() async
  { await Future.delayed( const Duration(seconds:2) ); // adds drama
    String myStuff = await whereAmI();
    String filePath = "$myStuff/stuff.txt";
    File fodder = File(filePath);
    String contents = fodder.readAsStringSync();
    print("-------------in readFile ...");
    print(contents);
    return contents;
  }

  Future<void> writeFile( String writeMe) async
  { String myStuff = await whereAmI();
    String filePath = "$myStuff/otherStuff.txt";
    File fodder = File(filePath);
    fodder.writeAsStringSync( writeMe );
  }
}