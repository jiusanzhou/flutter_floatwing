

import 'dart:isolate';

import 'package:flutter_floatwing/flutter_floatwing.dart';

typedef WindowListener = dynamic Function(Window, dynamic);

class EventManager {

  Window _window;
  String _prefix = "window.";

  EventManager(this._window);

  // event listenders
  Map<String, List<WindowListener>> _listeners = {};

  List<dynamic> sink(String method, dynamic args) {
    return (_listeners[method]??[]).map((e) => e(_window, args)).toList();
  }

  EventManager on(String name, WindowListener callback) {
    final key = "$_prefix$name";
    print("[event] register listener for $key");
    if (_listeners[key] == null) _listeners[key] = [];
    _listeners[key]?.add(callback);
    return this;
  }
}