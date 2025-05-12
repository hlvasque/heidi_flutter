// fd.dart  version 24
// Barrett Koster
// demo of HydratedCubit

import "dart:io";
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'f_d_state.dart';


void main() async
{ WidgetsFlutterBinding.ensureInitialized();
  Directory addx = await getApplicationDocumentsDirectory();
  String add = addx.path;
  HydratedBloc.storage =  await HydratedStorage.build
  (  storageDirectory: HydratedStorageDirectory
    ( (await getApplicationDocumentsDirectory()).path,),
  );
  print("add=$add");
  runApp(const FoodDiary());
}

class FoodDiary extends StatelessWidget
{ static const String header = "Food Diary 4";

  const FoodDiary({super.key});

  @override
  Widget build(BuildContext context) 
  { return MaterialApp
    ( title: header,
      home: BlocProvider<FDCubit>
      ( create: (context) => FDCubit(),
        child: BlocBuilder<FDCubit,FDState>
        ( builder: (context,state)
          { // FDCubit fdc =  BlocProvider.of<FDCubit>(context);
            return  Splash(title: header, /* fdc:fdc */ );
          },
        ),
      ),
    );
  }
}

class Splash extends StatelessWidget 
{ final String title;
  // final FDCubit fdc;
  const Splash({super.key, required this.title, /* required this.fdc */ } );

  @override
  Widget build(BuildContext context) 
  { FDCubit fdc = BlocProvider.of<FDCubit>(context);
    FDState fds = fdc.state;
    TextEditingController tec = TextEditingController();

    return Scaffold
    ( appBar: AppBar(  title: Text(title),),
      body: Column
      ( children: 
        [ Text(fds.food),
          SizedBox
          ( height:50, width:300,
            child: TextField(controller: tec ),
          ),
          ElevatedButton
          ( onPressed: (){ fdc.setFood(tec.text); },
            child: Text("submit"),
          ),
        ],
      ),
    );
  }     
}
