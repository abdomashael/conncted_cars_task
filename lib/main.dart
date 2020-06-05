//import 'dart:html';

//import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors/sensors.dart';
import 'package:location/location.dart';

void main() {
  runApp(MyApp());
}

const int MIN_SPEED = 10;
const int MAX_SPEED = 30;

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
  bool _serviceEnabled;
  PermissionStatus _permissionGranted;

  double _speed = 0;
  int _oldSpeed = 0;
  int _from10To30Time = 0;
  int _from30To10Time = 0;
  int _oldTime = 0;
  bool _isDown = false;
  bool _isUp = true;

  void _setSpeed(double newSpeed) {
    setState(() {
      _measureTime(newSpeed);
      _speed = newSpeed;
    });
  }

  @override
  void initState() {
    _listenToLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SpeedWidget(speed: _speed),
            AccelerometerWidget(from30To10Time: _from10To30Time, maxSpeed: MAX_SPEED, minSpeed: MIN_SPEED),
            AccelerometerWidget(from30To10Time: _from30To10Time,maxSpeed: MAX_SPEED,minSpeed: MIN_SPEED,),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkPermission(Location location) async {
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    }
    return true;
  }

  Future<bool> _checkServiceStatus(Location location) async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return false;
      } else {
        return true;
      }
    } else {
      return true;
    }
  }

  Future<void> _listenToLocation() async {
    Location location = new Location();
    await location.changeSettings(
        accuracy: LocationAccuracy.high, interval: 1000, distanceFilter: 0);
    bool serviceEnabled = await _checkServiceStatus(location);
    if (serviceEnabled) {
      bool havePermission = await _checkPermission(location);

      if (havePermission) {
        LocationData _locationData = await location.getLocation();
        _setSpeed(double.parse((_locationData.speed * 3.6).toStringAsFixed(2)));

        location.onLocationChanged.listen((LocationData currentLocation) {
          // Use current location
          print(currentLocation);
          setState(() {
            //to convert speed from m/s to km/h multiply by 3.6
            _setSpeed(
                double.parse((currentLocation.speed * 3.6).toStringAsFixed(2)));
          });
        });
      }
    }
  }

  /// the current time, in “seconds since the epoch”
  static int currentTimeInSeconds() {
    var ms = (new DateTime.now()).millisecondsSinceEpoch;
    return (ms / 1000).round();
  }

  void _measureTime(double currentSpeed) {
    int newSpeed = currentSpeed.round();

    bool inRangeOfMax = newSpeed >= MAX_SPEED - 2 && newSpeed <= MAX_SPEED + 2;
    bool inRangeOfMin = newSpeed >= MIN_SPEED - 2 && newSpeed <= MIN_SPEED + 2;

    if (inRangeOfMax && _oldSpeed == MIN_SPEED && _isUp) {
      int now = currentTimeInSeconds();
      _isUp = false;
      _isDown = true;
      _from10To30Time = now - _oldTime;
      _oldTime = now;
      _oldSpeed = MAX_SPEED;
    } else if (inRangeOfMin && _oldSpeed == MAX_SPEED && _isDown) {
      int now = currentTimeInSeconds();
      _isUp = true;
      _isDown = false;
      _from30To10Time = (now - _oldTime);
      _oldTime = now;
      _oldSpeed = MIN_SPEED;
    } else if (newSpeed == MIN_SPEED && _oldSpeed == 0) {
      // for first time
      _oldTime = currentTimeInSeconds();
      _oldSpeed = 10;
      _isUp = true;
      _isDown = false;
    } else if ((newSpeed == MAX_SPEED && _oldSpeed == MAX_SPEED) ||
        (newSpeed == MIN_SPEED && _oldSpeed == MIN_SPEED)) {
      _oldTime = currentTimeInSeconds();
    }
  }
}

class SpeedWidget extends StatelessWidget {
  const SpeedWidget({
    Key key,
    @required double speed,
  }) : _speed = speed, super(key: key);

  final double _speed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 16, 0, 32),
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
    );
  }
}

class AccelerometerWidget extends StatelessWidget {
  final int _maxSpeed,_minSpeed;
  final int _from30To10Time;


  const AccelerometerWidget({
    Key key,
    @required int from30To10Time,
    @required int maxSpeed,
    @required int minSpeed,

  }) : _from30To10Time = from30To10Time,_maxSpeed=maxSpeed,_minSpeed=minSpeed, super(key: key);


  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 16, 0, 16),
      child: Column(
        children: [
          Text(
            'From $_maxSpeed to $_minSpeed',
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
    );
  }
}
