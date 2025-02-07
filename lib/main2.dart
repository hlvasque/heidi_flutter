import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

//counter class
class Counter {
  int counter;
  Counter(this.counter);
}

class CounterCubit extends Cubit<Counter> {
  //initialize the counter to 0 here
  CounterCubit() : super(Counter(0));

  //increment counter using emit
  void incrementCounter() {
    emit(Counter(state.counter + 1));
  }
}

void main() {
  runApp(MyHomePage(title: 'Flutter Demo'));
}

class MyHomePage extends StatelessWidget {
  final String title;

  MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CounterCubit>(
      create: (context) => CounterCubit(),
      child: MaterialApp(
        title: title,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: _MyHomePageStat(),
      ),
    );
  }
}

class _MyHomePageStat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: BlocBuilder<CounterCubit, Counter>(
          builder: (context, state) {
            //show current counter value
            return Text('Counter: ${state.counter}');
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            BlocBuilder<CounterCubit, Counter>(
              builder: (context, state) {
                return Text(
                  //show current counter value
                  '${state.counter}',
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<CounterCubit>().incrementCounter();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
