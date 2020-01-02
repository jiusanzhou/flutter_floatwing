import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_floatwing/src/window.dart';

class FloatwingPlugin {

  FloatwingPlugin._() {
    _bgChannel.setMethodCallHandler((call) {
      switch (call.method) {
        case "window.resumed": {

        }
      }
      return Future.value(null);
    });
  }

  static const String channelID = "im.zoe.labs/flutter_floatwing";

  static final MethodChannel _channel = MethodChannel('$channelID/method');
  static final MethodChannel _bgChannel = MethodChannel('$channelID/bg_method');
  static final BasicMessageChannel _msgChannel = BasicMessageChannel('$channelID/bg_message', JSONMessageCodec());

  static final FloatwingPlugin _instance = FloatwingPlugin._();

  /// flag for inited
  bool _inited = false;

  /// permission granted already
  /// 
  bool? _permissionGranted;

  /// service running already
  /// 
  bool? _serviceRunning;

  /// _windows for the main engine to manage the windows started
  /// items added by start function
  Map<String, Window> _windows = {};

  /// reutrn all windows only works for main engine
  List<Window> get windows => _windows.entries.map<Window>((e) => e.value).toList();

  /// _window for the sub window engine to manage it's self
  /// setted after window's engine start and initital call
  Window? _window;

  /// return current window for window's engine
  Window? get currentWindow => _window;

  /// update the current window
  saveWindow(Window w) {
    _window = w;
  }

  factory FloatwingPlugin() {
    return _instance;
  }

  FloatwingPlugin get instance {
    return _instance;
  }

  Future<bool> initialize() async {
    if (_inited) return false;
    _inited = true;

    // get the callback id
    final CallbackHandle _cbId = PluginUtilities.getCallbackHandle(_callback)!;
    // if service started will return all windows
    var map = await _channel.invokeMapMethod("plugin.initialize", {
      // "start_service": true,
      "callback": _cbId.toRawHandle(),
    });

    print("initialize result: $map");

    _serviceRunning = map?["service_running"];
    _permissionGranted = map?["permission_grated"];

    (map?["windows"] as List<dynamic>?)?.map((e) {
      var w = Window.fromMap(e);
      _windows[w.id] = w;
    });

    print("there are ${_windows.length} windows already started");

    return true;
  }

  Future<bool> checkPermission() async {
    return await _channel.invokeMethod("plugin.has_permission");
  }

  Future<bool> openPermissionSetting() async {
    return await _channel.invokeMethod("plugin.open_permission_setting");
  }

  Future<bool> isServiceRunning() async {
    return await _channel.invokeMethod("plugin.is_service_running");
  }

  Future<bool> startService() async {
    return await _channel.invokeMethod("plugin.start_service");
  }

  Future<Window> createWindow(String? id, WindowConfig config) async {
    // check permission first
    if (!await checkPermission()) {
      throw Exception("no permission to create window");
    }
    var updates = await _channel.invokeMapMethod<String, dynamic>("plugin.start_window", {
      "id": id, "config": config.toMap()
    });
    var w = Window(config).applyMap(updates);
    // store the window to cache
    _windows[w.id] = w;
    return w;
  }

  Future<bool> closeWindow(String id, {bool hard = false}) async {
    return await _bgChannel.invokeMethod("service.close_window", {
      "id": id, "hard": hard,
    });
  }

  Future<Map<dynamic, dynamic>?> updateWindow(String id, WindowConfig config) async {
    var updates = await _bgChannel.invokeMapMethod("service.update_window", {
      "id": id,
      "config": config.toMap(),
    });
    print("plugin update window result<map>: $updates");
    // store the window to cache
    _windows[id]?.applyMap(updates);
    return updates;
  }

  Future<bool> showWindow(String id, bool v) async {
    return await _bgChannel.invokeMethod("service.show_window", [id, v]);
  }

  // Window? getWindow(String id) {
  //   return _windows[id];
  // }

  /// sync window return a window from engine
  /// when in the flutter don't known window object.
  Future<Window?> syncWindow() async {
    if (_window!=null) return _window;
    // create window and sync from service
    return Window(null).sync();

    // var map = await MethodChannel('$channelID/bg_method/window')
    //   .invokeMapMethod("window.init");
    // print("receive init call from android: $map");
    // var w = Window.fromMap(map);
    // // set to static
    // FloatwingPlugin()._window = w;
    // return w;
  }

  static void _callback() async {

  }
}