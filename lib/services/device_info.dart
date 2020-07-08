import 'dart:io';
import 'package:android_multiple_identifier/android_multiple_identifier.dart';

class DeviceInfo {
  Map info;

  Future<Map> init() async {
    if(info == null) {
      bool requestResponse = await AndroidMultipleIdentifier.requestPermission();
      if (!requestResponse) {
        exit(0);
      }

      try {
        info = await AndroidMultipleIdentifier.idMap;
      } catch (e) {
        info["imei"] = 'Unknown IMEI.';
        info["serial"] = 'Unknown Serial Code.';
        info["androidId"] = 'Unknown';
      }
    }
    return info;
  }
}