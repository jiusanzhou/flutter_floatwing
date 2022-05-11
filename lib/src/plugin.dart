import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floatwing/src/window.dart';

class FloatwingPlugin {
  FloatwingPlugin._() {
    WidgetsFlutterBinding.ensureInitialized();

    _bgChannel.setMethodCallHandler((call) {
      var id = call.arguments as String;
      // if we are window egine, should call main engine
      FloatwingPlugin().windows[id]?.eventManager?.sink(call.method, call.arguments);
      switch (call.method) {

      }
      return Future.value(null);
    });
  }

  static const String channelID = "im.zoe.labs/flutter_floatwing";

  static final MethodChannel _channel = MethodChannel('$channelID/method');
  static final MethodChannel _bgChannel = MethodChannel('$channelID/bg_method');
  static final BasicMessageChannel _msgChannel =
      BasicMessageChannel('$channelID/bg_message', JSONMessageCodec());

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
  Map<String, Window> get windows =>
      _windows; // _windows.entries.map<Window>((e) => e.value).toList();

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
    // final CallbackHandle _cbId = PluginUtilities.getCallbackHandle(_callback)!;
    // if service started will return all windows
    var map = await _channel.invokeMapMethod("plugin.initialize", {
      // "start_service": true,
      "pixelRadio": window.devicePixelRatio,
    });

    print("[plugin] initialize result: $map");

    _serviceRunning = map?["service_running"];
    _permissionGranted = map?["permission_grated"];

    var _ws = map?["windows"] as List<dynamic>?;
    _ws?.forEach((e) {
      var w = Window.fromMap(e);
      _windows[w.id] = w;
    });

    print("[plugin] there are ${_windows.length} windows already started");

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

  // create window object
  Future<Window> createWindow(
    String? id,
    WindowConfig config, {
    bool start = false, // start immediately if true
    Window? window,
  }) async {
    // check permission first
    if (!await checkPermission()) {
      throw Exception("no permission to create window");
    }
    var updates =
        await _channel.invokeMapMethod<String, dynamic>("plugin.create_window", {
      "id": id,
      "config": config.toMap(),
      "start": start,
    });
    var w = (window ?? Window()).applyMap(updates);
    // store the window to cache
    _windows[w.id] = w;
    return w;
  }

  /// ensure window make sure the window object sync from android
  /// call this as soon at posible when engine start
  /// you should only call this in the window engine
  /// if only main as entry point, it's ok to call this
  /// and return nothing
  Future<Window?> ensureWindow() async {
    return Window().sync();
  }

  // Future<bool> startWindow(String id) async {
  //   return await _bgChannel.invokeMethod("service.start_window", {
  //     "id": id
  //   });
  // }

  // Future<bool> closeWindow(String id, {bool force = false}) async {
  //   return await _bgChannel.invokeMethod("service.close_window", {
  //     "id": id,
  //     "force": force,
  //   });
  // }

  // Future<Map<dynamic, dynamic>?> updateWindow(
  //     String id, WindowConfig config) async {
  //   var updates = await _bgChannel.invokeMapMethod("service.update_window", {
  //     "id": id,
  //     "config": config.toMap(),
  //   });
  //   // store the window to cache
  //   _windows[id]?.applyMap(updates);
  //   return updates;
  // }

  // Future<bool> showWindow(String id, bool v) async {
  //   return await _bgChannel.invokeMethod("service.show_window", {
  //     "id": id,
  //     "visible": v
  //   });
  // }

  // Window? getWindow(String id) {
  //   return _windows[id];
  // }

  /// sync window return a window from engine
  /// when in the flutter don't known window object.
  // Future<Window?> syncWindow() async {
  //   if (_window != null) return _window;
  //   // create window and sync from service
  //   return Window(null).sync();

  //   // var map = await MethodChannel('$channelID/bg_method/window')
  //   //   .invokeMapMethod("window.init");
  //   // print("receive init call from android: $map");
  //   // var w = Window.fromMap(map);
  //   // // set to static
  //   // FloatwingPlugin()._window = w;
  //   // return w;
  // }

  static void _callback() async {}
}
