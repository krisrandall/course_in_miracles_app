import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
      title: 'A Course in Miracles',
      theme: ThemeData(
        fontFamily: 'Sparky',
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
  List<String> _completedLessons = [];
  
  void _loadLessons() async {

    // is it already downloaded into local storage ?
    final db = await SharedPreferences.getInstance();
    var lessonsJsonLocal;
    try {
      lessonsJsonLocal = db.getString('lessonsJSON');
      _lessons = (json.decode(lessonsJsonLocal) as List).map((i) => Lesson.fromJson(i)).toList();
    } catch(e) {
      print(e);
      // this is my error handling :o)
      _lessons = [
        Lesson(audio: '', lessonNumber: 'NO DATA', lessonShortTitle: 'Maybe no internet', lessonTitle: 'NO DATA', lessonText: e.toString(), fullTitle: '', link: ''),
      ];
    }

    // also fetch from server, in case of any changes
    try {
      var response = await http.get(Uri.parse(_dataSourceUrl));
      if (response.body != lessonsJsonLocal) {
        _lessons = (json.decode(response.body) as List).map((i) => Lesson.fromJson(i)).toList();
        await db.setString('lessonsJSON', response.body);
      }
    } catch (e) {
      print(e);
      // this is my error handling :o)
      if (_lessons.length < 2) {
        _lessons = [
          Lesson(audio: '', lessonNumber: 'NO DATA', lessonShortTitle: 'Maybe no internet', lessonTitle: 'NO DATA', lessonText: e.toString(), fullTitle: '', link: ''),
        ];      }
    }

    // also read the completed lessons from local storage
    _completedLessons = db.getStringList('completedLessons')??[];

    // and open up at the next lesson
    int nextLessonIndex() => _lessons.indexWhere((l) => !_completedLessons.contains(l.lessonNumber));
    _currentLessonIndex = nextLessonIndex();

    setState(() { });
  }

  void _toggleAsComplete(lesson) async {
    final db = await SharedPreferences.getInstance();
    if (!_completedLessons.contains(lesson.lessonNumber)) {
      _completedLessons.add(lesson.lessonNumber);
    } else {
      _completedLessons.remove(lesson.lessonNumber);
    }
    await db.setStringList('completedLessons', _completedLessons);
    setState(() { });
  } 

  @override
  initState() {
    super.initState();
    _loadLessons();
  }


  @override
  Widget build(BuildContext context) {

    final MENU_ITEM_HEIGHT = 70.0;
    Drawer sideMenu = Drawer(
      child: ListView(
        // set the starting position of the sideMenu to have the first incomplete lesson at the top
        controller: ScrollController(initialScrollOffset: (_completedLessons.isNotEmpty) ? _currentLessonIndex * MENU_ITEM_HEIGHT : 0.0),
        key: const PageStorageKey('sideMenu'),
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: [

          ..._lessons.map((l) => SizedBox( 
            height: MENU_ITEM_HEIGHT,
            child: ListTile(
              title: Text(l.lessonNumber),
              subtitle: Text(l.lessonShortTitle),
              trailing: // can tap on the icon to toggle as complete or not
                IconButton(
                  icon: const Icon(Icons.check_circle),
                  //color: (_completedLessons.contains(l.lessonNumber)) ? Colors.green : Colors.grey,
                  onPressed: () => _toggleAsComplete(l),
                ),
              iconColor: (_completedLessons.contains(l.lessonNumber)) ? Colors.green : Colors.grey,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentLessonIndex = _lessons.indexOf(l);
                });
              },
            ))).toList(),

        ],
      ),
    );

    if (_lessons.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
        ),
        drawer: sideMenu,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(_lessons[_currentLessonIndex].lessonNumber),
          actions: [
            // external link out to the original source
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                launchUrl(Uri.parse(_lessons[_currentLessonIndex].link));
              },
            ),
          ],
        ),
        drawer: sideMenu,
        // add a floating action button to mark the lesson as complete,
        // and to save that in local storage
        floatingActionButton: FloatingActionButton(
          onPressed: () => _toggleAsComplete(_lessons[_currentLessonIndex]),
          tooltip: 'Mark as complete',
          backgroundColor: (_completedLessons.contains(_lessons[_currentLessonIndex].lessonNumber)) ? Colors.green : Colors.grey,
          child: const Icon(Icons.check_circle),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding( 
                padding: const EdgeInsets.fromLTRB(20,20,20,0),
                child: Text(
                  _lessons[_currentLessonIndex].fullTitle??'', 
                  style: Theme.of(context).textTheme.headline5,
                ),
              ),
              Padding( 
                padding: const EdgeInsets.all(20),
                child: Html(
                  data: _lessons[_currentLessonIndex].lessonText??'',
                  style: {
                    ".snr": Style( display: Display.NONE), // these are some funky sub and super script chars in the original scraped data
                    ".pnr": Style( display: Display.NONE),
                  }
                ),
              ),
            ],
          ),
        ),
      );
    }

  }
}
