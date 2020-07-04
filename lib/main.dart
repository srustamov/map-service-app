import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

//import 'package:location/location.dart';
import 'package:flutter/material.dart';

//import 'package:http/http.dart' as http;
import 'package:background_location/background_location.dart';
import 'package:android_multiple_identifier/android_multiple_identifier.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() => runApp(Application());

class Application extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geo Location',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.red,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: MainPage(title: 'Location'),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MainPagePageState createState() => _MainPagePageState();
}

class _MainPagePageState extends State<MainPage> {
  Map _idMap = Map();
  IO.Socket socket;

  String latitude = "waiting...";
  String longitude = "waiting...";
  String altitude = "waiting...";
  String accuracy = "waiting...";
  String bearing = "waiting...";
  String speed = "waiting...";
  String time = "waiting...";

  @override
  void initState() {
    super.initState();

    socket = IO.io('https://abb68ab3b211.ngrok.io', <String, dynamic>{
      'transports': ['websocket'],
    });

    initIdentifierInfo();
//    var location = new Location();
//
//    location.onLocationChanged().listen((data) {
//      if (data != null) {
//        sendData(data);
//      }
//    });

    BackgroundLocation.getPermissions(
      onGranted: () {
        BackgroundLocation.startLocationService();
        BackgroundLocation.getLocationUpdates((location) {
          setState(() {
            this.latitude = location.latitude.toString();
            this.longitude = location.longitude.toString();
            this.accuracy = location.accuracy.toString();
            this.altitude = location.altitude.toString();
            this.bearing = location.bearing.toString();
            this.speed = location.speed.toString();
            this.time =
                DateTime.fromMillisecondsSinceEpoch(location.time.toInt())
                    .toString();
          });

          if (location != null) {
            sendData(location);
          }
        });
      },
      onDenied: () {

        exit(0);
      },
    );
  }

  void sendData(location) async {
    Map allData = {};

    Map infoData = {
      'id': _idMap['androidId'],
      'imei': _idMap['imei'],
      'serial': _idMap['serial'],
    };

    allData.addAll(infoData);
    allData.addAll({
      'latitude': 40.4631193,//location.latitude.toString(),
      'longitude': 50.0493061,//location.longitude.toString(),
      'accuracy': location.accuracy.toString(),
      'altitude': location.altitude.toString(),
      'bearing': location.bearing.toString(),
      'speed': location.speed.toString(),
      'time':
          DateTime.fromMillisecondsSinceEpoch(location.time.toInt()).toString()
    });
    socket.emit('make-location', json.encode(allData));
//    await http.post(
//      'https://abb68ab3b211.ngrok.io/location',
//      headers: <String, String> {
//        'Content-Type': 'application/json; charset=UTF-8',
//      },
//      body: json.encode({
//        'id': _idMap['androidId'],
//        'imei' : _idMap['imei'],
//        'serial' : _idMap['serial'],
//        'lathitude': data.latitude,
//        'longitude': data.longitude,
//      }),
//    );
  }

  Future<void> initIdentifierInfo() async {
    Map idMap;

    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      String platformVersion = await AndroidMultipleIdentifier.platformVersion;
    } on PlatformException {
      String platformVersion = 'Failed to get platform version.';
    }

    bool requestResponse = await AndroidMultipleIdentifier.requestPermission();
    print("NEVER ASK AGAIN SET TO: ${AndroidMultipleIdentifier.neverAskAgain}");

    try {
      idMap = await AndroidMultipleIdentifier.idMap;
    } catch (e) {
      idMap = Map();
      idMap["imei"] = 'Unknown IMEI.';
      idMap["serial"] = 'Unknown Serial Code.';
      idMap["androidId"] = 'Unknown';
    }

    if (!mounted) return;
    setState(() {
      _idMap = idMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(Platform.isAndroid ? 'Android Device' : 'iOS Device'),
        ),
        body: Center(
          heightFactor: MediaQuery.of(context).size.height,
          child: Container(
            margin: const EdgeInsets.all(30.0),
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              border: Border.all(),
            ),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: <Widget>[
                Text('IMEI:${_idMap["imei"]}'),
                Text('SERIAL:${_idMap["serial"]}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
