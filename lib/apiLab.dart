import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

//heidi vasquez
//dictionary api gives you all the definitions of a word
//https://dictionaryapi.dev/<word>

class MsgState {
  final String word;
  final List<String> def;

  MsgState(this.word, this.def);
}

class MsgCubit extends Cubit<MsgState> {
  MsgCubit() : super(MsgState("word", []));

  void update(String w, List<String> d) {
    emit(MsgState(w, d));
  }
}

void main() {
  runApp(const WeatherApi());
}

class WeatherApi extends StatelessWidget {
  const WeatherApi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'word definitions',
      home: Scaffold(
        appBar: AppBar(title: const Text('word definitions')),
        body: const Weather1(),
      ),
    );
  }
}

class Weather1 extends StatefulWidget {
  const Weather1({super.key});

  @override
  _Weather1State createState() => _Weather1State();
}

class _Weather1State extends State<Weather1> {
  final TextEditingController myController = TextEditingController();

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MsgCubit>(
      create: (context) => MsgCubit(),
      child: BlocBuilder<MsgCubit, MsgState>(
        builder: (context, state) {
          MsgCubit mc = BlocProvider.of<MsgCubit>(context);
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //show the word and definition
                Text(
                  'Word: ${mc.state.word}',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  'Definitions:',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: mc.state.def.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(mc.state.def[index]),
                      );
                    },
                  ),
                ),

                TextField(
                  controller: myController,
                  decoration: const InputDecoration(
                    labelText: 'Provide a word:',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    mc.update(value, ['Definitions not found yet']);
                  },
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    String word = myController.text;
                    List<String> defs = await _networkCall( word );
                    await Future.delayed( Duration(milliseconds:2000) );
                    mc.update(word, defs);
                  },
                  child: const Text('Get Definition'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<List<String>> _networkCall(String w) async
  {
    String currUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en/' + w;
    final url = Uri.parse( currUrl );
    final response = await http.get(url);
    //print( "response: ${response.body}" );
    //Map<String,dynamic> dataAsMap = jsonDecode(response.body);

    List<dynamic> dataAsList = jsonDecode(response.body); // This is a list, as the response is an array
    //print("Parsed Data: $dataAsList");

    //print( dataAsMap );
    //print(dataAsMap);
    //List<dynamic> meanings = dataAsMap['meanings'];

    List<String> defs = [];
    if( response.statusCode == 200 ) {
      print( "status code is 200" );

      var wordData = dataAsList[0];
      var meanings = wordData['meanings'] ?? [];

      for (var meaning in meanings) {
        var definitionsList = meaning['definitions'] ?? [];

        for (var definition in definitionsList) {
          print( definition['definition'] );
          defs.add(definition['definition'] ?? 'No definition available');
        }
      }
    }
    else print( "Status code not 200" );
   return defs;
  }
}
