import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(const QuizzleApp());
}

class QuizzleApp extends StatelessWidget {
  const QuizzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'heidi\'s quizzle',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const QuizScreen(),
    );
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  //create a list of key,value pairs (State, capitol)
  late List<Map<String, String>> quizData = [];
  late String questionLabel = ""; //state
  late String answerLabel = ""; //capitol

  //data that holds information about the current quiz session
  int currentQuestionIndex = 0; //what question are we on
  int correctAnswers = 0; //how many questions you've answered correctly
  bool showFeedback = false; //toggles app to show correct answer if you got it wrong
  bool isCorrect = false;
  String userAnswer = "";
  String feedback = "";

  //this sets a string variable to whatever the user entered into a text field
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    //initialize app
    super.initState();
    //set some dummy data
    questionLabel = "number";
    answerLabel = "word";
    quizData = List.from( {});
    loadQuizData();
  }

  //load in the actual questions/answers from the given text file
  Future<void> loadQuizData() async {
    try {
      print( "trying to load in file "); //for debugging in console
      String data = await rootBundle.loadString('lib/StateCapitols.txt');
      List<String> lines = LineSplitter.split(data).where((line) => line.trim().isNotEmpty).toList();

      //parse each line into an a bunch of strings
      //using "," as the delimiter
      List<String> header = lines[0].split(',');
      if (header.length >= 2) {
        questionLabel = header[0].trim();
        answerLabel = header[1].trim();
      }

      //construct question,value pairs using the array we created
      List<Map<String, String>> loadedData = [];
      for (int i = 1; i < lines.length; i++) {
        String line = lines[i];
        int commaIndex = line.indexOf(',');
        if (commaIndex != -1) {
          String question = line.substring(0, commaIndex).trim();
          String answer = line.substring(commaIndex + 1).trim();
          loadedData.add({question: answer});
        }
      }

      if (loadedData.isNotEmpty) {
        setState(() {
          quizData = loadedData;
          //if we read in valid data, reset the questions
          currentQuestionIndex = 0;
          correctAnswers = 0;
          showFeedback = false;
        });
      }
    } catch ( e ) {
      //if there's an error when we're reading in from the file,
      //don't display anthing at all -- just use the dummy data
      print('there was an error while reading in from the file!');
    }
  }

  //grab the current question
  String getCurrentQuestion() {
    if (currentQuestionIndex < quizData.length) {
      return quizData[currentQuestionIndex].keys.first;
    }
    return "";
  }

  //grab the answer for the curr question
  String getCorrectAnswer() {
    if (currentQuestionIndex < quizData.length) {
      return quizData[currentQuestionIndex][getCurrentQuestion()] ?? "";
    }
    return "";
  }

  //validate the user's answer
  void checkAnswer() {
    String userAnswerTrimmed = _answerController.text.trim().toLowerCase();
    String correctAnswerTrimmed = getCorrectAnswer().toLowerCase();

    setState(() {
      userAnswer = _answerController.text;
      isCorrect = userAnswerTrimmed == correctAnswerTrimmed;
      showFeedback = true;

      if (isCorrect) {
        correctAnswers++;
        feedback = "correct!";
      } else {
        feedback = "incorrect :( The correct answer is: ${getCorrectAnswer()}";
      }
    });
  }

  //load in the next question
  void nextQuestion() {
    setState(() {
      _answerController.clear();
      userAnswer = "";
      showFeedback = false;

      //before loading in the next question, make sure that we
      //havent' reached the end of the question list
      if (currentQuestionIndex < quizData.length - 1) {
        currentQuestionIndex++;
      } else {
        //else, congratulate user for reachign end!
        showFeedback = true;
        feedback = "quiz completed!";
      }
    });
  }

  //reset the quiz for some variety??
  void resetQuiz() {
    setState(() {
      _answerController.clear();
      userAnswer = "";
      showFeedback = false;
      currentQuestionIndex = 0;
      correctAnswers = 0;

      quizData.shuffle(Random());
    });
  }

  //quiz ui
  @override
  Widget build(BuildContext context) {
    bool quizCompleted = currentQuestionIndex >= quizData.length - 1 && showFeedback;

    return Scaffold(
      appBar: AppBar(
        title: const Text('quizzle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: resetQuiz,
            tooltip: 'reset Quiz',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //show how many questions we've answered so far
            Text(
              'answered ${currentQuestionIndex} out of ${quizData.length} questions',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            //show curr score
              Text(
                'score: $correctAnswers / ${quizData.length}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),


            const SizedBox(height: 24),

            //show quiz questions
            if (!quizCompleted && quizData.isNotEmpty) ...[
              //show prompt
              Text(
                'what\'s the answer $answerLabel for this $questionLabel?',
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 12),

              //curr question
              Text(
                getCurrentQuestion(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              //field for user to type in answer
              TextField(
                controller: _answerController,
                decoration: InputDecoration(
                  labelText: 'enter the $answerLabel',
                  border: const OutlineInputBorder(),
                  enabled: !showFeedback,
                ),
                onSubmitted: (_) => !showFeedback ? checkAnswer() : null,
              ),

              const SizedBox(height: 16),

              //submit answer
              if (!showFeedback)
                ElevatedButton(
                  onPressed: checkAnswer,
                  child: const Text('submit answer'),
                ),

              //display feedback to user answer submitting answer
              if (showFeedback) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    feedback,
                    style: TextStyle(
                      fontSize: 18,
                      color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 16),

                //btn to move onto next question
                ElevatedButton(
                  onPressed: nextQuestion,
                  child: Text(currentQuestionIndex < quizData.length - 1
                      ? 'next question'
                      : 'finish quiz'),
                ),
              ],
            ],

            //display msg when the user has reached the end of the quiz
            if (quizCompleted) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'quiz completed!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'your final score: $correctAnswers out of ${quizData.length}',
                      style: const TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      correctAnswers == quizData.length
                          ? 'oh wow, you got a perf score! congrats!'
                          : 'good job! but you can try again to improve your score',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: resetQuiz,
                      icon: const Icon(Icons.replay),
                      label: const Text('start new quiz'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }
}