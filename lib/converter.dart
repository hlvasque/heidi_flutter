import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'converter- heidi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Calculator(),
    );
  }
}

class Calculator extends StatefulWidget {
  @override
  _CalculatorState createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  //store the input string
  String input = '';
  //store the result/calculation
  String output = '';
  //the numerical version of the input string
  double num1 = 0.0;
  //use a string to keep track of which conversion will be performed
  String operation = '';

  //function that sets the operation type
  void buttonPress(String buttonText) {
    setState(() {
      input += buttonText;
    });
  }

  //toggles between positive and negative for the input
  void toggleSign() {
    setState(() {
      //if the sign is negative, set it to positive
      if (input.isNotEmpty && !input.contains('-')) {
        input = '-' + input;
      } else if (input.isNotEmpty && input.contains('-')) {
        //otherwise toggle to positive
        input = input.substring(1);
      }
    });
  }

  //clear input/output/operation type
  void clear() {
    setState(() {
      input = '';
      output = '';
      operation = '';
    });
  }

  //perform a calculation (based on what operation type was selected)
  void calculate() {
    setState(() {
      //check if an operation type has been selected
      //(ex C->F)
      num1 = double.tryParse(input) ?? 0.0;

      //CTOF = celcius to faranheit
      if (operation == 'CtoF') {
        output = ((num1 * 9 / 5) + 32).toStringAsFixed(2);
      } else if (operation == 'FtoC') {
        //FTOC = faramheit to celcius
        output = ((num1 - 32) * 5 / 9).toStringAsFixed(2);
      } else if (operation == 'PtoK') {
        //pTOK = pounds to kilo
        output = (num1 * 0.453592).toStringAsFixed(2);
      } else if (operation == 'KtoP') {
        //KTOP = kilo to pounds
        output = (num1 * 2.20462).toStringAsFixed(2);
      }

      //reset input/operation type after the calculation
      input = '';
      operation = '';
    });
  }

  //select the operation type to be performed
  void selectOperation(String operationType) {
    setState(() {
      operation = operationType;
    });
  }

  //build the buttons
  Widget buildButton(String buttonText) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          //execute a function based on which button was pressed
          if (buttonText == 'CLEAR') {
            //if the clear button was pressed, execute the clear function
            clear();
          } else if (buttonText == 'Submit') {
            //else if the submit button was pressed, perform a calculation
            //(calculate determines what operation is appropriate)
            calculate();
          } else if (buttonText == '+/-') {
            //else if the +/ button was selcted, toggle between pos/neg
            toggleSign();
          } else {
            //else if another button was pressed
            //this must be one of the buttons that specifies the operation type
            //ex C->F, P->K, etc
            buttonPress(buttonText);
          }
        },
        child: Text(
          buttonText,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  //set the operation type
  //the operationType is stored in buttonText
  //this button updates buttonText to C->F, F->C, etc
  Widget buildConversionButton(String buttonText, String operationType) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          selectOperation(operationType);
        },
        child: Text(
          buttonText,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('converter- heidi'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  input,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  output,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
          Row(
            children: [
              buildButton('7'),
              buildButton('8'),
              buildButton('9'),
              buildButton('CLEAR'),
            ],
          ),
          Row(
            children: [
              buildButton('4'),
              buildButton('5'),
              buildButton('6'),
              buildButton('0'),
            ],
          ),
          Row(
            children: [
              buildButton('1'),
              buildButton('2'),
              buildButton('3'),
              buildButton('.'),
            ],
          ),
          Row(
            children: [
              buildConversionButton('C -> F', 'CtoF'),  //celcius to farenheit
              buildConversionButton('F -> C', 'FtoC'),  //celcius to faranheit
            ],
          ),
          Row(
            children: [
              buildConversionButton('P -> K', 'PtoK'),  //pounds to kilo
              buildConversionButton('K -> P', 'KtoP'),  //kilo to pounds
            ],
          ),
          Row(
            children: [
              //toggle between pos/neg
              buildButton( '+/-'),
              buildButton('Submit'),
            ],
          ),
        ],
      ),
    );
  }
}
