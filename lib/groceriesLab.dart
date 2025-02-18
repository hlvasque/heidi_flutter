import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocery List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GroceryListScreen(),
    );
  }
}

class GroceryListScreen extends StatefulWidget {
  @override
  _GroceryListScreenState createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  List<String> _groceryList = [];
  bool _isLoading = true;  // Flag to track the loading state
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    //load in the list
    _loadGroceryList();
  }

  //load in the grocery list (simulated with Future.delayed)
  Future<void> _loadGroceryList() async {
    await Future.delayed(Duration(seconds: 2)); // adds drama
    final file = await _getLocalFile();
    if (await file.exists()) {
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      setState(() {
        _groceryList = jsonList.cast<String>();
        //update loading state after it's been set
        _isLoading = false;
      });
    } else {
      setState(() {
        _groceryList = [];
        //update the loading state
        _isLoading = false;
      });
    }
  }

  //save the grocery list
  Future<void> _saveGroceryList() async {
    final file = await _getLocalFile();
    final jsonList = jsonEncode(_groceryList);
    await file.writeAsString(jsonList);
  }

  //set a local file path
  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/grocery_list.json');
  }

  //append a new item to the grocery list
  void _addGroceryItem(String item) {
    if (item.isNotEmpty) {
      setState(() {
        _groceryList.add(item);
      });
      //save the updated list
      _saveGroceryList();
      //clear input field
      _controller.clear();
    }
  }

  //remove an item from the list
  void _removeGroceryItem(int index) {
    setState(() {
      _groceryList.removeAt(index);
    });
    //save the updated list
    _saveGroceryList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grocery List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Add Grocery Item'),
              onSubmitted: _addGroceryItem,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _groceryList.isEmpty
                //show msg saying that the list is empty
                ? Center(child: Text('No items in the grocery list!'))
                : ListView.builder(
              itemCount: _groceryList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_groceryList[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _removeGroceryItem(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
