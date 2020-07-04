import 'package:Geolocation/pages/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

void main() => runApp(Application());

class Application extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geo Location',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.red,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: MainPage(title: 'Location'),
    );
  }
}
