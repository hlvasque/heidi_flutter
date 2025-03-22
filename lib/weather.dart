// api key 576df1424ac54348ac8213823242110
// weatherapi.com

// Barrett Koster 2024


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
// from command line> flutter pub add http
// > flutter pub add flutter_bloc
// > flutter pub add http
// > flutter pub add web_socket_channel

// also must add to macos/Runner/DebugProfile.entitlements and 
// ..... Release.entitlements
// 	<key>com.apple.security.network.client</key>
// 	<true/>


import 'bb.dart';

void main() // Weather
{ runApp(const WeatherApi());
}

// just holds a string.  This will hold the 
// temperature 

class MsgState
{ String msg;
  MsgState( this.msg );
}
class MsgCubit extends Cubit<MsgState>
{ MsgCubit() : super( MsgState("999") );
  void update(String m) { emit(MsgState(m)); }
}

class WeatherApi extends StatelessWidget
{
 const WeatherApi({super.key});

  @override
  Widget build( BuildContext context )
  { return MaterialApp
    ( title: "weather demo",
      home: Scaffold
      ( appBar: AppBar( title: Text("weather demo") ),
        body: Row
        ( children:
          [ Weather1(),
          ],
        ),
      ),
    );
  }
}

class Weather1 extends StatelessWidget 
{ const Weather1({super.key});

  @override
  Widget build( BuildContext context )
  { return BlocProvider<MsgCubit>
    ( create: (context) => MsgCubit(),
      child: BlocBuilder<MsgCubit,MsgState>
      ( builder: (context, state)
        { return Builder
          ( builder: (context)
            { MsgCubit mc = BlocProvider.of<MsgCubit>(context);
              return Column
              ( children:
                [ Row
                  ( children:
                    [ BB("temp C"),
                      BB("${mc.state.msg}"),
                    ],
                  ),
                  ElevatedButton
                  ( onPressed: () async 
                    { String temp = await _networkCall(2);
                      await Future.delayed( Duration(milliseconds:2000) );
                      mc.update(temp);
                    },
                    child: BB("get temp"),
                  ),
                ],
              ); 
            },
          );
        },
      ),
    );
  }

  Future<String> _networkCall(int x) async
  {
    final url = Uri.parse('http://api.weatherapi.com/v1/current.json?key=2a724b73cd504d19b99202815251103&q=90007&aqi=no');
    //final url = Uri.parse('http://api.weatherapi.com/v1/current.json'
     //  '?key=576df1424ac54348ac8213823242110&q=90802&aqi=no');
    final response = await http.get(url);
    Map<String,dynamic> dataAsMap = jsonDecode(response.body);
    // print(dataAsMap);
    // for ( String k in dataAsMap.keys )
    // { print("k=$k"); }
    Map<String,dynamic> dig1 = dataAsMap['current'];
    double tempC = dig1['temp_c']; 
    String tempCstr = tempC.toString();
    // print("imgurl=$imgurl");
    return tempCstr;
  }
}
