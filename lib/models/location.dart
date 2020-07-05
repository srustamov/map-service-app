

class Location {
  var latitude;
  var longitude;
  var altitude;
  var accuracy;
  var bearing;
  var speed;
  var time;
  Location({this.latitude,this.longitude,this.altitude,this.accuracy,this.bearing,this.speed,this.time});

  Map toMap() {
    return {
      'latitude':latitude.toString(),
      'longitude':longitude.toString(),
      'accuracy': accuracy.toString(),
      'altitude': altitude.toString(),
      'bearing': bearing.toString(),
      'speed': speed.toString(),
      'time':
      DateTime.fromMillisecondsSinceEpoch(time.toInt()).toString()
    };
  }
}