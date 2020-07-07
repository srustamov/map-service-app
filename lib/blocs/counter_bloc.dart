import 'package:flutter/cupertino.dart';

class CounterBloc extends ChangeNotifier
{
  int _counter = 0;

  get counter => _counter;

  increment () => _counter++;
}