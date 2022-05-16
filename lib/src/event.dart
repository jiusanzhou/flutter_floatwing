import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

typedef WindowListener = dynamic Function(Window window, dynamic data);


/// events name
enum EventType {
  WindowCreated,
  WindowStarted,
  WindowPaused,
  WindowResumed,
  WindowDestroy,

  WindowDragStart,
  WindowDragging,
  WindowDragEnd,
}

extension _EventType on EventType {
  static final _names = {
    EventType.WindowCreated: "window.created",
    EventType.WindowStarted: "window.started",
    EventType.WindowPaused: "window.paused",
    EventType.WindowResumed: "window.resumed",
    EventType.WindowDestroy: "window.destroy",
    EventType.WindowDragStart: "window.drag_start",
    EventType.WindowDragging: "window.dragging",
    EventType.WindowDragEnd: "window.drag_end",
  };

  static EventType? fromString(String v) {
    EventType.values.firstWhere((e) => e.name==v);
  }

  String get name => _names[this]!;
}


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

// final SendPort? _send = IsolateNameServer.lookupPortByName(SEND_PORT_NAME);
class EventManager {
  EventManager._(this._msgChannel) {
    // set just for window, so window have no need to do this
    _msgChannel.setMessageHandler((msg) {
      var map = msg as Map<dynamic, dynamic>?;
      if (map == null) {
        log("[event] unsupported message, we except a map");
      }
      var evt = Event.fromMap(map!);
      var rs = sink(evt);
      log("[event] handled event: ${evt.name}, handlers: ${rs.length}");
      return Future.value(null);
    });
  }

  // event listenders
  // because enum from string O(n), so just use string
  // Map<String, Map<Window, List<WindowListener>>> _listeners = {};
  // w.id -> type -> w -> [cb]
  Map<String, Map<String, Map<Window, List<WindowListener>>>> _listeners = {};

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

  List<dynamic> sink(Event evt) {
    var res = [];
    // w.id -> type -> w -> [cb]

    // get windows
    var ws = (_listeners[evt.id] ?? {})[evt.name] ?? {};
    ws.forEach((w, cbs) {
      (cbs).forEach((c) {
        res.add(c(w, evt.data));
      });
    });
    return res;
  }

  EventManager on(Window window, EventType type, WindowListener callback) {
    var key = type.name;
    log("[event] register listener $key for $window");
    // w.id -> w -> type -> [cb]
    if (_listeners[window.id] == null) _listeners[window.id] = {};
    if (_listeners[window.id]![key] == null) _listeners[window.id]![key] = {};
    if (_listeners[window.id]![key]![window] == null) _listeners[window.id]![key]![window] = [];
    if (!_listeners[window.id]![key]![window]!.contains(callback))
      _listeners[window.id]![key]![window]!.add(callback);
    return this;
  }

  @override
  String toString() {
    return "EventManager@${super.hashCode}";
  }
}
