//import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors/sensors.dart';


void main() {
  runApp(MyApp());
}

const int minSpeed =10;
const int maxSpeed =30;

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connected Cars',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Connected Cars'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _speed = 0;
  int _oldSpeed = 0;
  int _from10To30Time = 0;
  int _from30To10Time = 0;
  int _oldTime = 0;
  bool _isDown = false;
  bool _isUp = true;

  void _setSpeed(int newSpeed) {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.

      measureTime(newSpeed);

// [UserAccelerometerEvent (x: 0.0, y: 0.0, z: 0.0)]
      _speed = newSpeed;
    });
  }

  /// the current time, in “seconds since the epoch”
  static int currentTimeInSeconds() {
    var ms = (new DateTime.now()).millisecondsSinceEpoch;
    return (ms / 1000).round();
  }


  void measureTime(int newSpeed) {
    if (newSpeed == maxSpeed && _oldSpeed == minSpeed && _isUp) {
      int now = currentTimeInSeconds();
      _isUp = false;
      _isDown = true;
      _from10To30Time = now - _oldTime;
      _oldTime = now;
      _oldSpeed = maxSpeed;
    } else if (newSpeed == minSpeed && _oldSpeed == maxSpeed && _isDown) {
      int now = currentTimeInSeconds();
      _isUp = true;
      _isDown = false;
      _from30To10Time = (now - _oldTime);
      _oldTime = now;
      _oldSpeed = minSpeed;
    } else if (newSpeed == minSpeed && _oldSpeed == 0) {
      // for first time
      _oldTime = currentTimeInSeconds();
      _oldSpeed = 10;
      _isUp = true;
      _isDown = false;
    } else if ((newSpeed == maxSpeed && _oldSpeed == maxSpeed) ||
        (newSpeed == minSpeed && _oldSpeed == minSpeed)) {
      _oldTime = currentTimeInSeconds();
    }
  }



  @override
  void initState() {

    userAccelerometerEvents.listen((UserAccelerometerEvent event) {
    //print((event.y).round().abs()*10);
    //Equation to convert every 1 m/s to kmh for testing only
      _setSpeed((event.y).round().abs()*10);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
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
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(0, 16, 0, 16),
              child: Column(
                children: [
                  Text(
                    'Current Speed',
                    style: TextStyle(fontSize: 35),
                  ),
                  Text(
                    '$_speed',
                    style: GoogleFonts.iceberg(
                        textStyle:
                            TextStyle(color: Colors.green, fontSize: 120)),
                  ),
                  Text(
                    "kmh",
                    style: TextStyle(fontSize: 35),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 16, 0, 16),
              child: Column(
                children: [
                  Text(
                    'From $minSpeed to $maxSpeed',
                    style: TextStyle(fontSize: 25),
                  ),
                  Text(
                    '$_from10To30Time',
                    style: GoogleFonts.iceberg(
                        textStyle:
                            TextStyle(color: Colors.green, fontSize: 50)),
                  ),
                  Text(
                    "seconds",
                    style: TextStyle(fontSize: 25),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 16, 0, 16),
              child: Column(
                children: [
                  Text(
                    'From $maxSpeed to $minSpeed',
                    style: TextStyle(fontSize: 25),
                  ),
                  Text(
                    '$_from30To10Time',
                    style: GoogleFonts.iceberg(
                        textStyle:
                            TextStyle(color: Colors.green, fontSize: 50)),
                  ),
                  Text(
                    "seconds",
                    style: TextStyle(fontSize: 25),
                  ),
                ],
              ),
            ),
//            RaisedButton(
//              child: const Text('-', style: TextStyle(fontSize: 20)),
//              onPressed: () {
//                if (_speed > 0) {
//                  _setSpeed(_speed - 10);
//                }
//              },
//            )
          ],
        ),
      ),
//      floatingActionButton: FloatingActionButton(
//        onPressed: () => {_setSpeed(_speed + 10)},
//        tooltip: 'Increment',
//        child: Icon(Icons.add),
//      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
