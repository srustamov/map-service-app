import 'package:flutter/material.dart';

Widget showData(String name, value) {
  return Card(
    elevation: 9.0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
    color: Colors.black54,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 50.0),
      child: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Text(
              name,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white),
              textAlign: TextAlign.start,
            ),
            Text(
              value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.yellowAccent,
              ),
              textAlign: TextAlign.end,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget showLoading({String text}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        CircularProgressIndicator(),
        SizedBox(
          height: 10.0,
        ),
        Text(
          text,
          style: TextStyle(color: Colors.deepOrange, fontSize: 20.0),
        )
      ],
    ),
  );
}

Future wait(seconds) {
  Duration s = Duration(seconds: seconds);
  return new Future.delayed(s, () => "1");
}
