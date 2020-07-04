import 'dart:convert';
import 'dart:io';
import 'package:background_location/background_location.dart';
import 'package:android_multiple_identifier/android_multiple_identifier.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MainPagePageState createState() => _MainPagePageState();
}

class _MainPagePageState extends State{
  Map _deviceInfo = Map();

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
            this.time = DateTime.fromMillisecondsSinceEpoch(location.time.toInt()).toString();
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
      'id': _deviceInfo['androidId'],
      'imei': _deviceInfo['imei'],
      'serial': _deviceInfo['serial'],
    };

    allData.addAll(infoData);
    allData.addAll({
      'latitude':location.latitude.toString(),
      'longitude':location.longitude.toString(),
      'accuracy': location.accuracy.toString(),
      'altitude': location.altitude.toString(),
      'bearing': location.bearing.toString(),
      'speed': location.speed.toString(),
      'time':
      DateTime.fromMillisecondsSinceEpoch(location.time.toInt()).toString()
    });
    socket.emit('make-location', json.encode(allData));
  }

  Future<void> initIdentifierInfo() async {
    Map idMap;

//    try {
//      String platformVersion = await AndroidMultipleIdentifier.platformVersion;
//    } on PlatformException {
//      String platformVersion = 'Failed to get platform version.';
//    }

    bool requestResponse = await AndroidMultipleIdentifier.requestPermission();
    if(!requestResponse) {
      exit(0);
    }

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
      _deviceInfo = idMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Geolocation'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
          heightFactor: MediaQuery.of(context).size.height,
          child: Container(
            padding: EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                locationData("IMEI", _deviceInfo["imei"]),
                locationData("SERIAL", _deviceInfo["serial"]),
                locationData("Latitude",latitude),
                locationData("Longitude ", longitude),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    FlatButton(
                        color: Colors.indigo,
                        textColor: Colors.white,
                        onPressed: () async {
                          await BackgroundLocation.startLocationService();
                          socket.connect();
                        },
                        child: Text("Start Location Service")
                    ),
                    FlatButton(
                        color: Colors.red,
                        textColor: Colors.white,
                        onPressed: () {
                          BackgroundLocation.stopLocationService();
                          socket.disconnect();
                          setState(() {
                            latitude = '';
                            longitude = '';
                          });
                        },
                        child: Text("Stop Location Service")
                    ),
                  ],
                )

              ],
            ),
          )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => BackgroundLocation().getCurrentLocation(),
        child: Icon(
          Icons.gps_fixed,
          color: Colors.white,
        ),
        backgroundColor: Colors.green,

      ),
    );
  }


  Widget locationData(String name,value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          textAlign: TextAlign.start,
        ),
        Text(
          value,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.purpleAccent
          ),
          textAlign: TextAlign.end,
        ),
      ],
    );

  }
}
