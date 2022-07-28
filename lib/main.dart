import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:signin_tracker_5567/person.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

List<Person> signInList = [];
Map<String, DateTime> currentlySignedIn = {};
String _currentSelect = "None";

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Sign In/Out'),
    );
  }
}

class MyDropdown extends StatefulWidget {
  final Stream<String> stream;
  const MyDropdown({required this.stream, Key? key}) : super(key: key);

  @override
  _MyDropdownState createState() => _MyDropdownState();
}

class _MyDropdownState extends State<MyDropdown> {
  late StreamSubscription subscription;

  @override
  void initState() {
    print("init drop");
    super.initState();
  }

  Future<void> setSubscription() async {
    try {
      subscription = widget.stream.listen((value) {
        setState(() {});
      });
    } catch (ignored) {
      print("oop");
    }
  }

  @override
  Widget build(BuildContext context) {
    setSubscription();

    return DropdownButtonHideUnderline(
      child: DropdownButton2(
        hint: Text(
          'Select Item',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).hintColor,
          ),
        ),
        items: currentlySignedIn.keys
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ))
            .toList(),
        value: _currentSelect,
        onChanged: (value) {
          setState(() {
            _currentSelect = value as String;
          });
        },
        buttonHeight: 40,
        buttonWidth: 140,
        itemHeight: 40,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();

  void _writeData() async {
    List<List<dynamic>> rows = [[]];
    for (Person person in signInList) {
      rows.add(person.toList());
    }
    final Directory? dir = await getExternalStorageDirectory();
    DateTime today = DateTime.now();
    String dateStr = "${today.day}-${today.month}-${today.year}--${today.hour}:${today.minute}";
    final file = File(join(dir!.path, dateStr + 'people.csv'));
    if (file.existsSync()) {
      file.deleteSync();
    }
    file.createSync();
    print(file.path);
    String csv = const ListToCsvConverter().convert(rows);
    file.writeAsString(csv);
  }

  void _addPerson(String name) {
    currentlySignedIn.putIfAbsent(name, () => DateTime.now());
  }

  void _signOut(String name) {
    _currentSelect = "None";
    Person signingOut = Person(
        name: name, signIn: currentlySignedIn.remove(name) ?? DateTime.now());
    signingOut.signOut = DateTime.now();
    signInList.add(signingOut);
  }

  final myController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    _writeData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    StreamController<String> _controller = StreamController<String>();
    currentlySignedIn.putIfAbsent("None", () => DateTime.now());
    print(currentlySignedIn.keys);
    final width = MediaQuery.of(context).size.width;
    const scalar = 0.05;
    const padding = 16.0;

    Widget button = const Padding(
        padding: EdgeInsets.all(padding));
    if (kDebugMode) {
      button = Padding(
          padding: const EdgeInsets.all(padding),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: Size(width * 0.1, width * 0.05),
                padding: const EdgeInsets.all(16)),
            child: Text(
              "Write Data",
              style: TextStyle(
                fontSize: width * scalar,
              ),
            ),
            onPressed: () {
              _writeData();
            },
          ));
    }

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.all(padding),
                      child: TextFormField(
                        controller: myController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please input your name';
                          }
                          return null;
                        },
                      )),
                  Padding(
                      padding: const EdgeInsets.all(padding),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            minimumSize: Size(width * 0.1, width * 0.05),
                            padding: const EdgeInsets.all(16)),
                        child: Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: width * scalar,
                          ),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _addPerson(myController.text);
                            myController.text = "";
                            _controller.sink.add("");
                          }
                        },
                      )),
                  Padding(
                      padding: const EdgeInsets.all(padding),
                      child: MyDropdown(stream: _controller.stream)),
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            minimumSize: Size(width * 0.1, width * 0.05),
                            padding: const EdgeInsets.all(16)),
                        child: Text(
                          "Sign Out",
                          style: TextStyle(
                            fontSize: width * scalar,
                          ),
                        ),
                        onPressed: () {
                          if (_currentSelect != "None") {
                            _signOut(_currentSelect);
                            _currentSelect = "None";
                            _controller.sink.add("None");
                          } else {
                            print("bad");
                          }
                        },
                      )),
                  button,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
