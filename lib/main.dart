import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'lessonStructure.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: const MyHomePage(title: 'A Course in Miracles'),
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
  
  String _dataSourceUrl = 'https://cocreations.com.au/a_course_in_miracles/lessons.json';
  List<Lesson> _lessons = [];
  int _currentLessonIndex = 0;

  
  void _loadLessons() async {
    var response = await http.get(Uri.parse(_dataSourceUrl));
    print(response);

    setState(() {
      _lessons = (json.decode(response.body) as List).map((i) => Lesson.fromJson(i)).toList();
    });
  }

  @override
  initState() {
    super.initState();
    _loadLessons();
  }


  @override
  Widget build(BuildContext context) {

    Drawer sideMenu = Drawer(
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: [

          ..._lessons.map((l) => ListTile(
            title: Text(l.lessonNumber),
            subtitle: Text(l.lessonShortTitle),
            trailing: const Icon(Icons.check_circle),
            iconColor: Colors.grey,
            onTap: () {
              // Update the state of the app.
              // ...
            },
          )).toList(),

          ListTile(
            title: const Text('Setting'),
            onTap: () {
              // Update the state of the app.
              // ...
            },
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: sideMenu,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_currentLessonIndex',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),

    );
  }
}
