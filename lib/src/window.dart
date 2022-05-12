import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_floatwing/flutter_floatwing.dart';
import 'package:flutter_floatwing/src/event.dart';

class Window {
  String id = "default";
  WindowConfig? config;

  double? pixelRadio;

  EventManager? _eventManager;

  Window({this.id = "default", this.config}) {
    // this will cause the channel called setHandler multi times
    _eventManager = EventManager(_message, window: this);
  }

  static final MethodChannel _channel =
      MethodChannel('${FloatwingPlugin.channelID}/window');
  static final BasicMessageChannel _message = BasicMessageChannel(
      '${FloatwingPlugin.channelID}/window_msg', JSONMessageCodec());

  factory Window.fromMap(Map<dynamic, dynamic>? map) {
    return Window().applyMap(map);
  }

  @override
  String toString() {
    return "Window[$id]@${super.hashCode}, ${_eventManager.toString()}, config: $config";
  }

  Window applyMap(Map<dynamic, dynamic>? map) {
    // apply the map to config and object
    if (map == null) return this;
    id = map["id"];
    pixelRadio = map["pixelRadio"] ?? 1.0;
    config = WindowConfig.fromMap(map["config"]);
    return this;
  }

  /// `of` extact window object window from context
  /// The data from the closest instance of this class that encloses the given
  /// context.
  static Window? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FloatwingProvider>()
        ?.window;
  }

  Future<bool?> hide() {
    return show(visible: false);
    // return FloatwingPlugin().showWindow(id, false);
  }

  Future<bool?> close({bool force = false}) async {
    // return await FloatwingPlugin().closeWindow(id, force: force);
    return await _channel.invokeMethod("window.close", {
      "id": id,
      "force": force,
    });
  }

  Future<Window?> create({bool start = false}) async {
    // // create the engine first
    return await FloatwingPlugin()
        .createWindow(this.id, this.config!, window: this);
  }

  Future<bool?> start() async {
    assert(config != null, "config can't be null");
    print("[window] invoke window.start for $this");
    return await _channel.invokeMethod("window.start", {
      "id": id,
    });
    // return await FloatwingPlugin().startWindow(id);
  }

  Future<bool> update(WindowConfig cfg) async {
    // update window with config, config con't update with id, entry, route
    var size = config?.size;
    if (size != null && size < Size.zero) {
      // special case, should updated
      cfg.width = null;
      cfg.height = null;
    }
    var updates = await _channel.invokeMapMethod("window.update", {
      "id": id,
      // don't set pixelRadio
      "config": cfg.toMap(),
    });
    // var updates = await FloatwingPlugin().updateWindow(id, cfg);
    applyMap(updates);
    return true;
  }

  Future<bool?> show({bool visible = true}) async {
    // return FloatwingPlugin().showWindow(id, v);
    config?.visible = visible;
    return await _channel.invokeMethod("window.show", {
      "id": id,
      "visible": visible,
    });
  }

  // sync window object from android service
  // only window engine call this
  // if we manage other windows in some window engine
  // this will not works, we must improve it
  static Future<Map<dynamic, dynamic>?> sync() async {
    return await _channel.invokeMapMethod("window.sync");
  }

  /// on register callback to listener
  Window on(
    String name,
    WindowListener callback, {
    String prefix = "window.",
  }) {
    var key = "$prefix$name";
    _eventManager?.on(this, key, callback);
    return this;
  }
}

class WindowConfig {
  String? id;

  String? entry;
  String? route;
  double? callback; // use callback to start engine

  bool? autosize;

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
    this.id = "default",
    this.entry = "main",
    this.route,
    this.callback,
    this.autosize,
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

      autosize: map["autosize"],

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

    map["autosize"] = autosize;

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

  // return a window frm config
  Window to() {
    // will lose window instance
    return Window(id: this.id ?? "default", config: this);
  }

  Future<Window> create({
    String? id = "default",
    bool start = false,
  }) async {
    assert(!(entry == "main" && route == null));
    return await FloatwingPlugin().createWindow(id, this, start: start);
  }

  Size get size => Size((width ?? 0).toDouble(), (height ?? 0).toDouble());

  @override
  String toString() {
    var map = this.toMap();
    map.removeWhere((key, value) => value == null);
    return json.encode(map).toString();
  }
}

enum Aligment {
  center,
}
