import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'lessonStructure.dart';
import 'package:html/dom.dart' as dom;

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


void printWrapped(String text) {
  final pattern = new RegExp('.{1,800}'); // 800 is the size of each chunk
  pattern.allMatches(text).forEach((match) => print(match.group(0)));
}

class _MyHomePageState extends State<MyHomePage> {
  
  String _dataSourceUrl = 'https://cocreations.com.au/a_course_in_miracles/lessons.json';
  List<Lesson> _lessons = [];
  int _currentLessonIndex = 0;
  List<String> _completedLessons = [];
  
  void _loadLessons() async {

    // is it already downloaded into local storage ?
    final db = await SharedPreferences.getInstance();
    List<dynamic> lessonsJsonLocal = [];
    try {
      lessonsJsonLocal = json.decode(Lesson.sanatise(db.getString('lessons--Json')??''));
      if (lessonsJsonLocal.isNotEmpty) {
        for (var i =0; i < lessonsJsonLocal.length; i++) {
          //printWrapped('loading ($i) from server');
          try {
            var l = Lesson.fromJson((lessonsJsonLocal)[i]);
            //print('--Loaded $l');
            _lessons.add(l);
          } catch (e) {
            print('**** failed to load LOCAL lesson $i ****');
            print(e);
          }
        }
      }
    } catch(e) {
      debugPrint('***** local storage load exception ****');
      print(e);
    }

    // also fetch from server, in case of any changes
    try {
      var response = await http.get(Uri.parse(_dataSourceUrl));
      List<dynamic> mList = (json.decode( Lesson.sanatise(response.body)) as List);
      if (mList != lessonsJsonLocal) {
        for (var i =0; i < mList.length; i++) {
          //printWrapped('loading ($i) from server');
          try {
            //print('about to load lesson $i  : ${mList[i]}');
            var l = Lesson.fromJson( json.decode(Lesson.sanatise(json.encode(mList[i]))));
            //print('--Loaded $l');
            _lessons.add(l);
          } catch (e) {
            print('**** failed to load lesson $i ****');
            print(e);
          }
        }
        await db.setString('lessons--Json', response.body);
      }
    } catch (e) {
      debugPrint('***** OTHER server load exception ****');
      print(e);
      // this is my error handling :o)
      if (_lessons.length < 2) {
        _lessons = [
          Lesson(audio: '', lessonNumber: 'NO DATA', lessonShortTitle: 'Maybe no internet', lessonTitle: 'NO DATA', lessonText: e.toString(), fullTitle: '', link: ''),
        ];      }
    }

    // also read the completed lessons from local storage
    _completedLessons = db.getStringList('completedLessons')??[];

    // if there are completed lessons, then start at the first incomplete lesson
    if (_completedLessons.isNotEmpty) {
      int nextLessonIndex() => _lessons.indexWhere((l) => !_completedLessons.contains(l.lessonNumber)) + 1; // +1 because of the Introduction "Lesson" below
      _currentLessonIndex = nextLessonIndex();
    }

    // Finally add an Intro/About page - and just hack it in there as a "Lesson"
    _lessons.insert(0, 
      Lesson(
        audio: '', 
        lessonNumber: 'Introduction', 
        lessonShortTitle: '', 
        lessonTitle: '', 
        lessonText: '''

This app is a convenient way to do <i>A Course in Miracles</i>.<br/><br/>

For one year do a single lesson every day.<br/><br/>
Do not do more than one lesson per day.<br/>You need not do a lesson every single day.<br/><br/>

<br/>
A Course in Miracles Resources:<br/><br/>
<ul>
<li><a href="https://acim.org/acim/workbook/introduction/en/s/401">Workbook Introduction</a></li>
<li><a href="https://acim.org/acim/text/introduction/en/s/51">Full Text of A Course in Miracles</a></li>
<li><a href="https://www.youtube.com/watch?v=5hWJN4J-nyI">Audio book of A Course in Miracles (YouTube)</a></li>
<li><a href="https://www.youtube.com/watch?v=C_L9EW95xcA">A Return to Love (YouTube)</a><br/></li>
</ul>

<br/><br/>

Use the menu to the left to navigate to the lessons.<br/><br/>


''',
        fullTitle: '', 
        link: 'https://cocreations.com.au',
      )
    );
    

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
        padding: const EdgeInsets.fromLTRB(0, 40, 0, 10),
        children: [

          ..._lessons.map((l) => SizedBox( 
            height: MENU_ITEM_HEIGHT,
            child: ListTile(
              title: Text(l.lessonNumber??'Null'),
              subtitle: Text(l.lessonShortTitle??'Null', maxLines: 2),
              trailing: 
                (l.lessonNumber == 'Introduction') ? null :
                  IconButton(
                    icon: const Icon(Icons.check_circle),
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
          title: const Text('Loading Miracles ...'),
        ),
        drawer: sideMenu,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(_lessons[_currentLessonIndex].lessonNumber??'Null'),
          actions: [
            // external link out to the original source
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                launchUrl(Uri.parse(_lessons[_currentLessonIndex].link??'Null'));
              },
            ),
          ],
        ),
        drawer: sideMenu,
        // add a floating action button to mark the lesson as complete,
        // and to save that in local storage
        floatingActionButton: (_lessons[_currentLessonIndex].lessonNumber == 'Introduction') ? null : FloatingActionButton(
          onPressed: () => _toggleAsComplete(_lessons[_currentLessonIndex]),
          tooltip: 'Mark as complete',
          backgroundColor: (_completedLessons.contains(_lessons[_currentLessonIndex].lessonNumber)) ? Colors.green : Colors.grey,
          child: const Icon(Icons.check, size: 40),
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
                  },
                  onLinkTap: (String? url, RenderContext context, Map<String, String> attributes, dom.Element? element) {
                    launchUrl(Uri.parse(url!));
                  }
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      );
    }

  }
}
