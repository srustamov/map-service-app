import 'dart:convert';
import 'dart:io';
import 'package:background_location/background_location.dart';
import 'package:android_multiple_identifier/android_multiple_identifier.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';

//const  SOCKET_URL = 'https://abb68ab3b211.ngrok.io';
const  SOCKET_URL = 'http://192.168.1.102:3000';

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MainPagePageState createState() => _MainPagePageState();
}

class _MainPagePageState extends State{

  Map _deviceInfo = Map();
  IO.Socket socket;

  String latitude  = "";
  String longitude = "";


  @override
  void initState() {
    super.initState();
    socket = IO.io(SOCKET_URL, <String, dynamic>{
      'transports': ['websocket'],
    });
    initIdentifierInfo();
    startBackgroundLocationService();
  }

  void startBackgroundLocationService() {
    BackgroundLocation.getPermissions(
      onGranted: () {
        BackgroundLocation.startLocationService();
        BackgroundLocation.getLocationUpdates((location) {
          if (location != null) {
            setState(() {
              this.latitude = location.latitude.toString();
              this.longitude = location.longitude.toString();
            });
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

    Map data = {};

    data.addAll(location.toMap());

    data.addAll({
      'id': _deviceInfo['androidId'],
      'imei': _deviceInfo['imei'],
      'serial': _deviceInfo['serial'],
    });

    socket.emit('make-location', json.encode(data));
  }

  Future<void> initIdentifierInfo() async {
    Map idMap;

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
          value.toString(),
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
