import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:Geolocation/blocs/theme_bloc.dart';
import 'package:Geolocation/models/theme.dart';
import 'package:background_location/background_location.dart';
import 'package:android_multiple_identifier/android_multiple_identifier.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:vibration/vibration.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  createState() => _HomePageState();
}

class _HomePageState extends State {
  bool _isPrepare = true;
  Timer _notificationTimer;
  String _notification = '';
  bool _notificationVibrate = false;
  Map _deviceInfo = Map();
  IO.Socket socket;
  String socketUrl = '';

  String latitude = "";
  String longitude = "";

  bool _locationServiceStatus = false;

  @override
  Widget build(BuildContext context) {
    final ThemeBloc themeBloc = Provider.of<ThemeBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Geolocation'),
        backgroundColor: Colors.green,
        actions: <Widget>[
            FlatButton(
              onPressed: () {
                if(themeBloc.isDarkTheme()) {
                  themeBloc.setTheme(ThemeModel().lightTheme);
                } else {
                  themeBloc.setTheme(ThemeModel().darkTheme);
                }
              },
              child: Icon(themeBloc.isDarkTheme() ? Icons.brightness_7 : Icons.brightness_4),
            )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraint) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraint.maxHeight),
              child:Container(
                width:constraint.maxWidth ,
                child: _isPrepare
                    ? Center(child: CircularProgressIndicator(),)
                    : Container(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      notificationBanner(),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('Vibrate'),
                          Switch(
                            value: _notificationVibrate,
                            onChanged: (value) {
                              setState(() {
                                _notificationVibrate = value;
                              });
                              if(value) {
                                putVibrate();
                              }
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeColor: Colors.green,
                          )
                        ],
                      ),
                      locationData("IMEI", _deviceInfo["imei"]),
                      locationData("Latitude", latitude),
                      locationData("Longitude ", longitude),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          !_locationServiceStatus ? RawMaterialButton(
                              elevation: 10.0,
                              fillColor: Colors.teal,
                              onPressed: () async {
                                await BackgroundLocation
                                    .startLocationService();
                                socket.connect();
                                setState(() {
                                  _locationServiceStatus = true;
                                });
                              },
                              padding: EdgeInsets.all(25.0),
                              shape: CircleBorder(),
                              child: Text("Start",style: TextStyle(color: Colors.white))
                          )
                          : RawMaterialButton(
                              padding: EdgeInsets.all(25.0),
                              elevation: 10.0,
                              fillColor: Colors.red,
                              onPressed: () {
                                BackgroundLocation.stopLocationService();
                                socket.disconnect();
                                setState(() {
                                  latitude = '';
                                  longitude = '';
                                });
                                setState(() {
                                  _locationServiceStatus = false;
                                });
                              },
                              shape: CircleBorder(),
                              child: Text("Stop",style: TextStyle(color: Colors.white),)),
                        ],
                      )
                    ],
                  ),
                ),
              )
            ),
          );
        },
      ),

//      floatingActionButton: FloatingActionButton(
//        onPressed: () => BackgroundLocation().getCurrentLocation(),
//        child: Icon(
//          Icons.gps_fixed,
//          color: Colors.white,
//        ),
//        backgroundColor: Colors.green,
//      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then((value) {
      if (value == ConnectivityResult.none) {
        showAlertDialog('Check internet connection');
      } else {
        prepareApp();
      }
    });
  }

  void putVibrate() {
    if(_notificationVibrate) {
      Vibration.hasVibrator().then((value) => Vibration.vibrate());
    }
  }

  void prepareApp() {
    if (socketUrl.isEmpty) {
      http.get('https://support.edi.az/geo.php').then((value) {
        if (value.statusCode == 200) {
          setState(() {
            socketUrl = value.body;
          });
          initBaseServices();
        }
      });
    } else {
      initBaseServices();
    }
  }

  void initBaseServices() {
    socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('notification', (data) {
      setState(() {
        _notification = data;
      });
      _notificationTimer.cancel();
      _notificationTimer = new Timer(const Duration(seconds: 5), () {
        putVibrate();
        setState(() {
          _notification = '';
        });
      });
    });

    initIdentifierInfo();
    startBackgroundLocationService();
    setState(() {
      _isPrepare = false;
    });
  }

  void startBackgroundLocationService() {
    BackgroundLocation.getPermissions(
      onGranted: () {
        BackgroundLocation.startLocationService();
        setState(() {
          _locationServiceStatus = true;
        });
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

  Future<void> initIdentifierInfo() async {
    Map idMap;

    bool requestResponse = await AndroidMultipleIdentifier.requestPermission();
    if (!requestResponse) {
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

  showAlertDialog(String message) {
    putVibrate();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: Colors.blueAccent,
              elevation: 20.0,
              title: Text(message),
              actions: <Widget>[
                FlatButton(
                  onPressed: () => exit(0),
                  child: Text(
                    'exit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
        barrierDismissible: true);
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

  Widget notificationBanner() {
    return _notification.isNotEmpty
        ? Container(
            padding: EdgeInsets.all(5.0),
            color: Colors.pink,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  _notification.toString(),
                  style: TextStyle(color: Colors.white),
                ),
                FlatButton(
                  onPressed: () {
                    setState(() {
                      _notification = '';
                    });
                  },
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                )
              ],
            ),
          )
        : Container();
  }

  Widget locationData(String name, value) {
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
              color: Colors.purpleAccent),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }
}
