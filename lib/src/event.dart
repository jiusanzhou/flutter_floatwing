import 'package:flutter/services.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

typedef WindowListener = dynamic Function(Window window, dynamic data);

/// Event is a common event
class Event {
  /// id is window id
  String? id;

  /// name is the event name
  String? name;

  /// data is the payload for event
  dynamic data;

  Event({
    this.id,
    this.name,
    this.data,
  });

  factory Event.fromMap(Map<dynamic, dynamic> map) {
    return Event(id: map["id"], name: map["name"], data: map["data"]);
  }
}

class EventManager {
  EventManager._(this._msgChannel) {
    // set just for window, so window have no need to do this
    _msgChannel.setMessageHandler((msg) {
      var map = msg as Map<dynamic, dynamic>?;
      if (map == null) {
        print("[event] unsupported message, we except a map");
      }
      var evt = Event.fromMap(map!);
      var rs = sink(evt);
      print("[event] handled event: ${evt.name}, handlers: ${rs.length}");
      return Future.value(null);
    });
  }

  Window? Function(Event evt)? chooseWindow;

  Map<String, List<Window>> _windows = {};

  BasicMessageChannel _msgChannel;

  // make sure one channel must only have one instance
  static final Map<String, EventManager> _instances = {};

  factory EventManager(
    BasicMessageChannel _msgChannel, {
    Window? window,
  }) {
    if (_instances[_msgChannel.name] == null) {
      _instances[_msgChannel.name] = EventManager._(_msgChannel);
    }

    var current = _instances[_msgChannel.name]!;

    // store the window which create the event manager
    if (window != null) {
      if (current._windows[window.id] == null) current._windows[window.id] = [];
      current._windows[window.id]!.add(window);
    }

    // make sure one message channel only one event manager
    return current;
  }

  // event listenders
  Map<String, Map<Window, List<WindowListener>>> _listeners = {};

  List<dynamic> sink(Event evt) {
    var res = [];
    (_listeners[evt.name] ?? {}).forEach((w, cbs) {
      (cbs).forEach((c) {
        res.add(c(w, evt.data));
      });
    });
    return res;
  }

  EventManager on(Window window, String name, WindowListener callback) {
    var key = name;
    print("[event] register listener $key for $window");
    if (_listeners[key] == null) _listeners[key] = {};
    if (_listeners[key]![window] == null) _listeners[key]![window] = [];
    if (!_listeners[key]![window]!.contains(callback))
      _listeners[key]![window]!.add(callback);
    return this;
  }

  @override
  String toString() {
    return "EventManager@${super.hashCode}";
  }
}
