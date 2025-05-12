
// pd8.dart
// from StackOverflow lepsch 2022
// Barrett Koster hacking into ... ?
// adding record 

// add permission lines to macos/Runner/*.entitlements
//    <key>com.apple.security.device.audio-input</key>
//    <true/>



import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class AState
{
  AudioPlayer thep;
  AudioRecorder ther;

  AState( this.thep, this.ther );


}
class ACubit extends Cubit<AState>
{
  ACubit() : super( AState( AudioPlayer(), AudioRecorder() ) );

  void play() // put these in the project/assets folder
  {
    state.thep.play(AssetSource('x.mp3'));
  }
  void playy()
  {
    state.thep.play(AssetSource('y.mp4'));
  }
  
  void playName( String s ) async
  { 
    final dir = await getApplicationDocumentsDirectory();
    final filename = "$s.mp4";
    String path = "${dir.path}/$filename";
    // path = "assets/x.mp3"; hack
    print("trying to play $path");
    state.thep.play(AssetSource(path) );
    //state.thep.play( AudioPlayer.asset("wef");
    state.thep.play(AssetSource("wef.mp3"));

  }

  void stop()
  {
    state.thep.stop();
  }

  void record( String s) async
  {
    final bool hasPermish = await state.ther.hasPermission();
    if (!hasPermish)
    { print("no permission to record");
      return;
    }
    else { print("you have permission to record."); }

    const config = RecordConfig
    ( encoder: AudioEncoder.aacLc,
      sampleRate: 44100,
      bitRate: 128000,
    );

    // String s = "y";
    final dir = await getApplicationDocumentsDirectory();
    final filename = "$s.mp4";
    String path = "${dir.path}/$filename";

    await state.ther.start( config, path: path); // works rec 9
    // await state.ther.start( config, path: filename); // works in weird dir, not dox

 }

  void stoprec() async
  { print("trying to stop");
    final path = await state.ther.stop();
    print("recording at: $path");
  }
/*

*/

}

void main()
{ runApp(const SoundDemo());
}

class SoundDemo extends StatelessWidget
{
  const SoundDemo({super.key});

  @override
  Widget build(BuildContext context)
  { return MaterialApp
    ( title: 'sound demo 7',
      home: SoundDemo2(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SoundDemo2 extends StatelessWidget
{
  @override
  Widget build( BuildContext context )
  { return BlocProvider<ACubit>
    ( create: (context) => ACubit(),
      child: BlocBuilder<ACubit,AState>
      ( builder: (context,state) => SoundDemo3(),
      ),
    );
  }
}

class SoundDemo3 extends StatelessWidget
{
  @override
  Widget build( BuildContext context )
  { 
    ACubit ac = BlocProvider.of<ACubit>(context);

    return Scaffold
    ( appBar: AppBar( title: Text("sound demo 7") ),
      body: Column
      ( children:
        [ 
          ElevatedButton
          ( onPressed: (){ ac.playy(); },
            child: Text("play asset y"),
          ),
          ElevatedButton
          ( onPressed: (){ ac.play(); },
            child: Text("play asset x"),
          ),
          ElevatedButton
          ( onPressed: (){ ac.stop(); },
            child: Text("stop x"),
          ),
          ElevatedButton
          ( onPressed: (){ ac.record("y"); },
            child: Text("record y"),
          ),
          ElevatedButton
          ( onPressed: (){ ac.stoprec(); },
            child: Text("stop recording"),
          ),
          ElevatedButton
          ( onPressed: (){ ac.playName("y"); },
            child: Text("play y"),
          ),
        ],
      ),
    );
  }
}
