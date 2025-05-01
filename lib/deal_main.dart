/*
HW for ITP-368
Your goal is to write a GUI app that let's the user play Deal Or No Deal (once through). (See
videos on the Web if you have never seen it.) I am reducing the number of suitcases to 10 so that
it does not take so long to play it (and test it). And I'm ditching the 3-at-a-time phase so it is
easier to program.
heidi vasquez
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';

void main() {
  runApp(const DealOrNoDealApp());
}

class DealOrNoDealApp extends StatelessWidget {
  const DealOrNoDealApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deal or No Deal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const DealOrNoDealGame(),
    );
  }
}

class DealOrNoDealGame extends StatefulWidget {
  const DealOrNoDealGame({super.key});

  @override
  DealOrNoDealGameState createState() => DealOrNoDealGameState();
}

class DealOrNoDealGameState extends State<DealOrNoDealGame> {
  //hard-coded values
  static const List<int> allValues = [1, 5, 10, 100, 1000, 5000, 10000, 100000, 500000, 1000000];
  static const int numSuitcases = 10;

  //maintain game state
  List<int> suitcaseValues = List.from(allValues);
  Set<int> openedSuitcases = {};
  int? playerSuitcase;
  int? currentOffer;
  bool gameEnded = false;
  bool offerStage = false;
  String endMessage = '';
  Random random = Random();

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  //initialize game
  void _newGame() {
    setState(() {
      suitcaseValues = List.from(allValues);
      suitcaseValues.shuffle();
      openedSuitcases = {};
      playerSuitcase = null;
      currentOffer = null;
      gameEnded = false;
      offerStage = false;
      endMessage = '';
    });
    _saveGame();
  }

  //calc dealer's offer (90% of average remaining value)
  int _calculateOffer() {
    List<int> remainingValues = [];
    for (int i = 0; i < numSuitcases; i++) {
      if (i != playerSuitcase && !openedSuitcases.contains(i)) {
        remainingValues.add(suitcaseValues[i]);
      }
    }

    if (remainingValues.isEmpty) return 0;

    double average = remainingValues.reduce((a, b) => a + b) / remainingValues.length;
    return (average * 0.9).round();
  }

  //select a suitcase
  void _selectSuitcase(int index) {
    if (gameEnded) return;

    setState(() {
      if (playerSuitcase == null) {
        //first suitcase
        playerSuitcase = index;
        offerStage = true;
        currentOffer = _calculateOffer();
      } else if (!offerStage && !openedSuitcases.contains(index) && index != playerSuitcase) {
        //open a suitcase
        openedSuitcases.add(index);

        //check if this is the last case remaining
        if (openedSuitcases.length == numSuitcases - 1) {
          //game over!
          gameEnded = true;
          endMessage = 'Game over! You won \$${suitcaseValues[playerSuitcase!]}';
        } else {
          //make a new offer
          offerStage = true;
          currentOffer = _calculateOffer();
        }
      }
    });
    _saveGame();
  }

  //if a deal gets accepted
  void _acceptDeal() {
    if (!offerStage || gameEnded) return;

    setState(() {
      gameEnded = true;
      endMessage = 'deal! you won \$${currentOffer!}';
    });
    _saveGame();
  }

  //if a deal is rejected
  void _rejectDeal() {
    if (!offerStage || gameEnded) return;

    setState(() {
      offerStage = false;
    });
    _saveGame();
  }

  //save state
  Future<void> _saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('suitcaseValues', jsonEncode(suitcaseValues));
    prefs.setString('openedSuitcases', jsonEncode(openedSuitcases.toList()));
    prefs.setInt('playerSuitcase', playerSuitcase ?? -1);
    prefs.setBool('gameEnded', gameEnded);
    prefs.setBool('offerStage', offerStage);
    prefs.setString('endMessage', endMessage);
    prefs.setInt('currentOffer', currentOffer ?? -1);
  }

  //load game
  Future<void> _loadGame() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('suitcaseValues')) {
      setState(() {
        suitcaseValues = List<int>.from(jsonDecode(prefs.getString('suitcaseValues')!));
        openedSuitcases = Set<int>.from(jsonDecode(prefs.getString('openedSuitcases')!));
        int savedPlayerSuitcase = prefs.getInt('playerSuitcase') ?? -1;
        playerSuitcase = savedPlayerSuitcase >= 0 ? savedPlayerSuitcase : null;
        gameEnded = prefs.getBool('gameEnded') ?? false;
        offerStage = prefs.getBool('offerStage') ?? false;
        endMessage = prefs.getString('endMessage') ?? '';
        int savedOffer = prefs.getInt('currentOffer') ?? -1;
        currentOffer = savedOffer >= 0 ? savedOffer : null;
      });
    } else {
      _newGame();
    }
  }

  //get remaining values
  List<int> _getRemainingValues() {
    List<int> result = [];
    for (int i = 0; i < suitcaseValues.length; i++) {
      if (!openedSuitcases.contains(i) && i != playerSuitcase) {
        result.add(suitcaseValues[i]);
      }
    }
    return result..sort();
  }

  @override
  Widget build(BuildContext context) {
    //sort values for display
    List<int> sortedValues = List.from(allValues);
    sortedValues.sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deal or No Deal'),
        actions: [
          TextButton(
            onPressed:
            _newGame,
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.keyD && offerStage) {
              _acceptDeal();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyN && offerStage) {
              _rejectDeal();

              return KeyEventResult.handled;
            } else if (event.logicalKey.keyLabel.length == 1) {
              try {
                int number = int.parse(event.logicalKey.keyLabel);
                if (number >= 0 && number < numSuitcases) {
                  if (!offerStage && !openedSuitcases.contains(number) && number != playerSuitcase) {
                    _selectSuitcase(number);
                    return KeyEventResult.handled;
                  } else if (playerSuitcase == null) {
                    _selectSuitcase(number);
                    return KeyEventResult.handled;
                  }
                }
              } catch (e) {
                // Not a number, ignore
              }
            }
          }
          return KeyEventResult.ignored;
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Game status
              if (playerSuitcase == null)
                const Text(
                  'Choose your suitcase to hold',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                )
              else if (offerStage && !gameEnded)
                Column(
                  children: [
                    Text(
                      'the banker offers you: \$${currentOffer!}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _acceptDeal,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('DEAL (D)', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: _rejectDeal,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('NO DEAL (N)', style: TextStyle(fontSize: 20)),
                        ),
                      ],
                    ),
                  ],
                )
              else if (!offerStage && !gameEnded)
                  Text(
                    'Your suitcase: ${playerSuitcase!}. Pick a suitcase to open.',
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  )
                else if (gameEnded)
                    Text(
                      endMessage,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                      textAlign: TextAlign.center,
                    ),

              const SizedBox(height: 20),

              // Values table
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Values Remaining:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: sortedValues.map((value) {
                        final isOpened = !_getRemainingValues().contains(value);
                        return Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isOpened ? Colors.grey : Colors.yellow,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '\$${value}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isOpened ? Colors.white : Colors.black,
                              decoration: isOpened ? TextDecoration.lineThrough : null,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Suitcases grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: numSuitcases,
                  itemBuilder: (context, index) {
                    bool isPlayerCase = playerSuitcase == index;
                    bool isOpened = openedSuitcases.contains(index);
                    bool canSelect = (playerSuitcase == null) ||
                        (!offerStage && !isOpened && !isPlayerCase);

                    return InkWell(
                      onTap: canSelect ? () => _selectSuitcase(index) : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isPlayerCase ? Colors.blue : (isOpened ? Colors.grey.shade300 : Colors.amber),
                          borderRadius: BorderRadius.circular(8),
                          border: isPlayerCase
                              ? Border.all(color: Colors.blue.shade800, width: 3)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$index',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isOpened ? Colors.grey : Colors.black,
                              ),
                            ),
                            if (isOpened)
                              Text(
                                '\$${suitcaseValues[index]}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            if (isPlayerCase && !isOpened)
                              const Icon(Icons.person, color: Colors.white),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}