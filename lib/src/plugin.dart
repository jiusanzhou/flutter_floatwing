import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

class FloatwingPlugin {
  FloatwingPlugin._() {
    WidgetsFlutterBinding.ensureInitialized();

    // make sure this only be called once
    // what happens when multiple window instances
    // are created and register event handlers?
    // Window().on(): id -> [Window, Window]
    // _eventManager = EventManager(_msgChannel);

    // _bgChannel.setMethodCallHandler((call) {
    //   var id = call.arguments as String;
    //   // if we are window egine, should call main engine
    //   FloatwingPlugin().windows[id]?.eventManager?.sink(call.method, call.arguments);
    //   switch (call.method) {

    //   }
    //   return Future.value(null);
    // });
  }

  static const String channelID = "im.zoe.labs/flutter_floatwing";

  static final MethodChannel _channel = MethodChannel('$channelID/method');

  // Reserved for future background communication
  // ignore: unused_field
  static final MethodChannel _bgChannel = MethodChannel('$channelID/bg_method');

  // Reserved for future message-based communication
  // ignore: unused_field
  static final BasicMessageChannel _msgChannel =
      BasicMessageChannel('$channelID/bg_message', JSONMessageCodec());

  static final FloatwingPlugin _instance = FloatwingPlugin._();

  /// event manager
  // EventManager? _eventManager;

  /// flag for inited
  bool _inited = false;

  /// permission granted already (updated by initialize)
  // ignore: unused_field
  bool? _permissionGranted;

  /// service running already (updated by initialize)
  // ignore: unused_field
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

  /// i'm window engine, default is the main engine
  /// if we sync success, we set to true.
  bool get isWindow => _isWindow;
  bool _isWindow = false;

  factory FloatwingPlugin() {
    return _instance;
  }

  FloatwingPlugin get instance {
    return _instance;
  }

  /// sync make the plugin to sync windows from services
  Future<bool> syncWindows() async {
    var _ws = await _channel.invokeListMethod("plugin.sync_windows");
    _ws?.forEach((e) {
      var w = Window.fromMap(e);
      _windows[w.id] = w;
    });
    return true;
  }

  Future<SystemConfig> _getValidSystemConfig() async {
    var config = SystemConfig();
    if (config.screenWidth != null &&
        config.screenWidth! > 0 &&
        config.screenHeight != null &&
        config.screenHeight! > 0) {
      return config;
    }

    final completer = Completer<SystemConfig>();
    void checkMetrics(Duration _) {
      final view = PlatformDispatcher.instance.implicitView;
      final size = view?.physicalSize ?? Size.zero;
      if (size.width > 0 && size.height > 0) {
        completer.complete(SystemConfig());
      } else {
        WidgetsBinding.instance.addPostFrameCallback(checkMetrics);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(checkMetrics);
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => config,
    );
  }

  Future<bool> initialize() async {
    if (_inited) return false;
    _inited = true;

    final systemConfig = await _getValidSystemConfig();
    final view = PlatformDispatcher.instance.implicitView;

    var map = await _channel.invokeMapMethod("plugin.initialize", {
      "pixelRadio": view?.devicePixelRatio ?? 1.0,
      "system": systemConfig.toMap(),
    });

    log("[plugin] initialize result: $map");

    _serviceRunning = map?["service_running"];
    _permissionGranted = map?["permission_grated"];

    var ws = map?["windows"] as List<dynamic>?;
    ws?.forEach((e) {
      var w = Window.fromMap(e);
      _windows[w.id] = w;
    });

    log("[plugin] there are ${_windows.length} windows already started");

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

  Future<bool> cleanCache() async {
    return await _channel.invokeMethod("plugin.clean_cache");
  }

  /// create window to create a window
  Future<Window?> createWindow(
    String? id,
    WindowConfig config, {
    bool start = false, // start immediately if true
    Window? window,
  }) async {
    var w = isWindow
        ? await currentWindow?.createChildWindow(id, config,
            start: start, window: window)
        : await internalCreateWindow(id, config,
            start: start, window: window, channel: _channel);
    if (w == null) return null;
    // store current window for window engine
    // for window engine use, update the current window
    // if we use create_window first?
    // _window = w; // we should don't use create_window first!!!
    // store the window to cache
    _windows[w.id] = w;
    return w;
  }

  // create window object for main engine
  Future<Window?> internalCreateWindow(
    String? id,
    WindowConfig config, {
    bool start = false, // start immediately if true
    Window? window,
    required MethodChannel channel,
    String name = "plugin.create_window",
  }) async {
    // check permission first
    if (!await checkPermission()) {
      throw Exception("no permission to create window");
    }

    // store the window first
    // window.id can't be updated
    // for main engine use
    // if (window != null) _windows[window.id] = window;
    var updates = await channel.invokeMapMethod(name, {
      "id": id,
      "config": config.toMap(),
      "start": start,
    });
    // if window is not created, new one
    return updates == null ? null : (window ?? Window()).applyMap(updates);
  }

  /// ensure window make sure the window object sync from android
  /// call this as soon at posible when engine start
  /// you should only call this in the window engine
  /// if only main as entry point, it's ok to call this
  /// and return nothing
  // only window engine call this
  // make sure window engine return only one window from every where
  Future<Window?> ensureWindow() async {
    // window object don't have sync method, we must do at here
    // assert if you are in main engine should call this
    var map = await Window.sync();
    log("[window] sync window object from android: $map");
    if (map == null) return null;
    // store current window if needed
    // use the static window first
    // so sync will return only one instance of window
    // improve this logic
    // means first time call sync, just create a new window
    if (_window == null) _window = Window();
    _window!.applyMap(map);
    _isWindow = true;
    return _window;
  }

  /// `on` register event handlers for all windows
  /// or we can use stream mode
  FloatwingPlugin on(EventType type, WindowListener callback) {
    // TODO:
    return this;
  }
}
