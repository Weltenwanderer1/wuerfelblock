import 'package:flutter/services.dart';

class ColordiceOrientation {
  ColordiceOrientation._();

  static int _locks = 0;
  static Future<void> _pending = Future<void>.value();

  static void acquire() {
    _locks++;
    if (_locks != 1) return;
    _set(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  static void release() {
    if (_locks == 0) return;
    _locks--;
    if (_locks != 0) return;
    _set(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  static void _set(List<DeviceOrientation> orientations) {
    _pending = _pending
        .catchError((_) {})
        .then((_) => SystemChrome.setPreferredOrientations(orientations));
  }
}
