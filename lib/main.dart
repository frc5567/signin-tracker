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

/// People who have signed in and out
List<Person> signInList = [];

/// Map of people who are currently signed in
Map<String, DateTime> currentlySignedIn = {};

/// Default dropdown string
const _defaultDropdown = "Select your name";

/// currently selected option for dropdown
String _currentSelect = _defaultDropdown;


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign In Tracker',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const MyHomePage(title: 'Sign In/Out'),
    );
  }
}

/// Custom dropdown menu, encapsulates dropdown for easier management
class MyDropdown extends StatefulWidget {
  final Stream<String> stream;
  const MyDropdown({required this.stream, Key? key}) : super(key: key);

  @override
  _MyDropdownState createState() => _MyDropdownState();
}

class _MyDropdownState extends State<MyDropdown> {
  late StreamSubscription subscription;

  /// Subscribe so we can update the dropdown menu when the available values change.
  /// This basically lets our other widgets update our state.
  Future<void> setSubscription() async {
    try {
      subscription = widget.stream.listen((value) {
        setState(() {});
      });
    } catch (ignored) {
      if (kDebugMode) {
        print("Subscription failed, likely because we were already subscribed");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ideally this would only be called on Widget init, but that just didn't
    // work for me, hence calling it here and the try catch hack for resubscribing
    setSubscription();

    return DropdownButtonHideUnderline(
      child: DropdownButton2(
        hint: Text(
          'Select Item',
          style: TextStyle(
            fontSize: 24,
            color: Theme.of(context).hintColor,
          ),
        ),
        // Map the names of people currently signed in as dropdown items
        items: currentlySignedIn.keys
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 24,
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
        // yes constants here are bad, but this will only run on our tablets,
        // so we can ignore flexibility
        buttonHeight: 120,
        buttonWidth: 420,
        itemHeight: 40,
        buttonPadding: const EdgeInsets.all(16),
        dropdownPadding: const EdgeInsets.all(16),
        buttonDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.black26,
          ),
        ),
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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }


  // try to save whenever app state changes - i.e. we go to home screen
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _writeData();
        break;
      case AppLifecycleState.resumed:
        // do nothing on resume
        break;
    }
    setState(() {});
  }

  /// Writes the data currently saved to a csv
  void _writeData() async {
    List<List<dynamic>> rows = [[]];
    // add each person who has signed in and out to the list
    for (Person person in signInList) {
      rows.add(person.toList());
    }

    // add people who have not signed out to the list
    for (var person in currentlySignedIn.entries) {
      rows.add([person.key, person.value, ""]);
    }

    // get the external directory for writing
    final Directory? dir = await getExternalStorageDirectory();

    // grab the current time and create a string
    DateTime today = DateTime.now();
    String dateStr =
        "${today.day}-${today.month}-${today.year}--${today.hour}:${today.minute}";

    // create a file, deleting it if one already exists, and write csv to it
    final file = File(join(dir!.path, dateStr + '.csv'));
    if (file.existsSync()) {
      file.deleteSync();
    }
    file.createSync();
    if (kDebugMode) {
      print(file.path);
    }
    String csv = const ListToCsvConverter().convert(rows);
    file.writeAsString(csv);
  }

  /// Add a person to our map
  void _addPerson(String name) {
    currentlySignedIn.putIfAbsent(name, () => DateTime.now());
  }

  /// Remove a person to our map and add them to the list with a sign out time
  void _signOut(String name) {
    _currentSelect = _defaultDropdown;
    Person signingOut = Person(
        name: name, signIn: currentlySignedIn.remove(name) ?? DateTime.now());
    signingOut.signOut = DateTime.now();
    signInList.add(signingOut);
  }

  /// Text editing controller to allow us to empty name input field
  final myController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    // this doesn't seem to work but \shrug
    _writeData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // create stream controller to send events to our dropdown
    StreamController<String> _controller = StreamController<String>();

    // add default value to our list. This will appear in csv, but so be it
    currentlySignedIn.putIfAbsent(_defaultDropdown, () => DateTime.now());

    // screen size data for scaling our button
    final width = MediaQuery.of(context).size.width;
    const scalar = 0.05;
    const padding = 16.0;

    // declare button widget so we can remove the "WriteData" button in release
    Widget button = const Padding(padding: EdgeInsets.all(padding));
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
                        style: const TextStyle(fontSize: 24),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Enter your name',
                        ),
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
                          if (_currentSelect != _defaultDropdown) {
                            _signOut(_currentSelect);
                            _currentSelect = _defaultDropdown;
                            _controller.sink.add("Select your name");
                          } else {
                            if (kDebugMode) {
                              print(
                                  "You've tried to delete the \""+ _defaultDropdown + "\" entry. Don't do that.");
                            }
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
