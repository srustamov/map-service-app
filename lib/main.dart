import 'package:Geolocation/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Geolocation/blocs/theme_bloc.dart';
//import 'package:Geolocation/blocs/counter_bloc.dart';

void main() => runApp(Application());

class Application extends StatelessWidget {
  @override
  Widget build(BuildContext context) {


    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeBloc>(
          create: (_) => ThemeBloc (),
        )
      ],
      child:  ChangeNotifierProvider (
        create: (_) => ThemeBloc (),
        builder: (context, child) {
          ThemeBloc themeBloc = Provider.of<ThemeBloc>(context);

          return MaterialApp(
            title: 'Geo Location',
            debugShowCheckedModeBanner: false,
            theme: themeBloc.getTheme(),//ThemeModel().darkTheme,
            home: HomePage(title: 'Location'),
          );
        },
      ),
    );
  }
}
