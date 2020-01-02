import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_floatwing/flutter_floatwing.dart';

class Window extends ChangeNotifier {
  String id = "default";
  WindowConfig? config;

  Window(this.config) {
    _channel.setMethodCallHandler((call) {
      switch (call.method) {
        case "window.resumed": {
          // how to notify window to reload the page
          print("receive from service, engine resumed");
          notifyListeners();
        }
      }
      return Future.value(null);
    });
  }

  static final MethodChannel _channel = MethodChannel('${FloatwingPlugin.channelID}/bg_method/window');

  factory Window.fromMap(Map<dynamic, dynamic>? map) {
    return Window(null).applyMap(map);
  }

  @override
  String toString() {
    return "Window[$id]: $config";
  }

  Window applyMap(Map<dynamic, dynamic>? map) {
    // apply the map to config and object
    if (map==null) return this;
    id = map["id"];
    config = WindowConfig.fromMap(map["config"]);
    return this;
  }

  /// `of` extact window object window from context
  /// The data from the closest instance of this class that encloses the given
  /// context.
  static Window? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FloatwingProvider>()?.window;
  }

  Future<bool> show({bool v = true}) {
    return FloatwingPlugin().showWindow(id, v);
  }

  Future<bool> hide() {
    return FloatwingPlugin().showWindow(id, false);
  }

  Future<bool> close({ bool hard = false }) async {
    return await FloatwingPlugin().closeWindow(id, hard: hard);
  }

  Future<bool> update(WindowConfig cfg) async {
    // update window with config, config con't update with id, entry, route
    var size = config?.size;
    if (size!=null&&size<Size.zero) {
      // special case, should updated
      cfg.width = null;
      cfg.height = null;
    }

    var updates = await FloatwingPlugin().updateWindow(id, cfg);
    print("update window result: $updates");
    applyMap(updates);
    return true;
  }

  // sync window object from android service
  Future<Window?> sync() async {
    var map = await _channel.invokeMapMethod("window.init");
    print("receive init call from android: $map");
    if (map == null) return null;
    applyMap(map);
    FloatwingPlugin().saveWindow(this);
    return this;
  }
}

class WindowConfig {
  // String? id;
  String? entry;
  String? route;
  double? callback; // use callback to start engine

  int? width;
  int? height;
  int? x;
  int? y;

  int? format;
  int? gravity;
  int? type;

  bool? clickable;
  bool? draggable;
  bool? focusable;

  /// immersion status bar
  bool? immersion;

  bool? visible;

  /// we need this for update, so must wihtout default value
  WindowConfig({
    // this.id = "default",
    this.entry = "main",
    this.route,
    this.callback,

    this.width,
    this.height,
    this.x,
    this.y,
    
    this.format,
    this.gravity,
    this.type,

    this.clickable,
    this.draggable,
    this.focusable,

    this.immersion,

    this.visible,
  });

  factory WindowConfig.fromMap(Map<dynamic, dynamic> map) {
    return WindowConfig(
      // id: map["id"],
      entry: map["entry"],
      route: map["route"],
      callback: map["callback"],

      width: map["width"],
      height: map["height"],
      x: map["x"],
      y: map["y"],

      format: map["format"],
      gravity: map["gravity"],
      type: map["type"],

      clickable: map["clickable"],
      draggable: map["draggable"],
      focusable: map["focusable"],

      immersion: map["immersion"],

      visible: map["visible"],
    );
  }

  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    // map["id"] = id;
    map["entry"] = entry;
    map["route"] = route;
    map["callback"] = callback;

    map["width"] = width;
    map["height"] = height;
    map["x"] = x;
    map["y"] = y;

    map["format"] = format;
    map["gravity"] = gravity;
    map["type"] = type;

    map["clickable"] = clickable;
    map["draggable"] = draggable;
    map["focusable"] = focusable;

    map["immersion"] = immersion;

    map["visible"] = visible;

    return map;
  }

  Future<Window> start({String? id = "default"}) async {
    assert(!(entry == "main" && route == null));
    return await FloatwingPlugin().createWindow(id, this);
  }

  Size get size => Size((width??0).toDouble(), (height??0).toDouble());

  @override
  String toString() {
    return json.encode(this.toMap()).toString();
  }
}

enum Aligment {
  center,
}