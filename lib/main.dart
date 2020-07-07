import 'package:Geolocation/pages/main_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';



void main() => runApp(
    ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => ThemeNotifier(ThemeCustomData().darkTheme),
      child:Application(),
    ),
);

class Application extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      title: 'Geo Location',
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.getTheme(),
      home: MainPage(title: 'Location'),
    );
  }
}
