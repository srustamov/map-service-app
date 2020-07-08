import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Geolocation/models/theme.dart';

class ThemeBloc extends ChangeNotifier {
  ThemeData _themeData = ThemeModel().darkTheme;

  getTheme() => _themeData;

  setTheme(ThemeData themeData) async {
    _themeData = themeData;
    notifyListeners();
  }

  isDarkTheme() {
    return _themeData == ThemeModel().darkTheme;
  }
}
