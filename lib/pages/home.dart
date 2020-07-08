import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:Geolocation/blocs/theme_bloc.dart';
import 'package:Geolocation/components/home.dart';
import 'package:Geolocation/models/theme.dart';
import 'package:Geolocation/services/device_info.dart';
import 'package:background_location/background_location.dart';
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
  bool loading = true;
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
        backgroundColor: Colors.orange,
        actions: <Widget>[
          FlatButton(
            onPressed: () {
              if (themeBloc.isDarkTheme()) {
                themeBloc.setTheme(ThemeModel().lightTheme);
              } else {
                themeBloc.setTheme(ThemeModel().darkTheme);
              }
            },
            child: Icon(themeBloc.isDarkTheme()
                ? Icons.brightness_7
                : Icons.brightness_4),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraint) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraint.maxHeight),
              child: Container(
                width: constraint.maxWidth,
                child: loading
                    ? showLoading(text: 'Preparing...')
                    : Container(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            notificationBanner(),
                            showData("IMEI", _deviceInfo["imei"]),
                            showData("Latitude", latitude),
                            showData("Longitude ", longitude),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                !_locationServiceStatus
                                    ? RawMaterialButton(
                                        elevation: 20.0,
                                        fillColor: Colors.teal,
                                        onPressed: () async {
                                          setState(() {
                                            loading = true;
                                          });

                                          await BackgroundLocation
                                              .startLocationService();
                                          socket.connect();
                                          await wait(10);
                                          setState(() {
                                            _locationServiceStatus = true;
                                            loading = false;
                                          });
                                        },
                                        padding: EdgeInsets.all(20.0),
                                        shape: CircleBorder(),
                                        child: Icon(
                                          Icons.my_location,
                                          size: 50.0,
                                        ),
                                      )
                                    : RawMaterialButton(
                                        hoverElevation: 0,
                                        padding: EdgeInsets.all(20.0),
                                        elevation: 10.0,
                                        fillColor: Colors.red,
                                        onPressed: () {
                                          setState(() {
                                            loading = true;
                                          });
                                          BackgroundLocation
                                              .stopLocationService();
                                          socket.disconnect();
                                          setState(() {
                                            latitude = '';
                                            longitude = '';
                                          });
                                          setState(() {
                                            _locationServiceStatus = false;
                                            loading = false;
                                          });
                                        },
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(50.0),
                                        ),
                                        child: Text(
                                          "STOP",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ],
                            )
                          ],
                        ),
                      ),
              ),
            ),
          );
        },
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            SizedBox(
              height: 20.0,
            ),
            Card(
              elevation: 15.0,
              child: ListTile(
                onTap: () {
                  setState(() {
                    _notificationVibrate = !_notificationVibrate;
                  });
                },
                leading: Icon(Icons.vibration),
                title: Text(
                  'Vibration',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                trailing: Switch(
                  value: _notificationVibrate,
                  onChanged: (value) {
                    setState(() {
                      _notificationVibrate = value;
                    });
                    if (value) {
                      putVibrate();
                    }
                  },
                  activeTrackColor: Colors.lightGreenAccent,
                  activeColor: Colors.green,
                ),
                enabled: true,
              ),
            ),
          ],
        ),
      ),
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
    if (_notificationVibrate) {
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
      _notificationTimer?.cancel();
      _notificationTimer = new Timer(const Duration(seconds: 5), () {
        putVibrate();
        setState(() {
          _notification = '';
        });
      });
    });

    //initIdentifierInfo();
    DeviceInfo().init().then((info) {
      _deviceInfo = info;
      startBackgroundLocationService();
      setState(() {
        loading = false;
      });
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

  void showAlertDialog(String message) {
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
      barrierDismissible: true,
    );
  }

  void sendData(location) async {
    Map data = {};
    data.addAll({
      "latitude": location.latitude,
      "longitude": location.longitude,
      "altitude": location.altitude,
      "accuracy": location.accuracy,
      "bearing": location.bearing,
      "speed": location.speed,
      "time": location.time,
    });
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
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.pink,
            ),
            padding: EdgeInsets.all(5.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    _notification.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17.0,
                    ),
                  ),
                ),
                RawMaterialButton(
                  padding: EdgeInsets.all(5.0),
                  elevation: 10.0,
                  fillColor: Colors.white,
                  onPressed: () {
                    setState(() {
                      _notification = '';
                    });
                  },
                  shape: CircleBorder(),
                  child: Icon(
                    Icons.close,
                    color: Colors.red,
                  ),
                )
              ],
            ),
          )
        : Container();
  }
}
