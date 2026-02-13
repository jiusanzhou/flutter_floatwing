import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FloatwingPlugin', () {
    const MethodChannel methodChannel =
        MethodChannel('im.zoe.labs/flutter_floatwing/method');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel,
              (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'plugin.has_permission':
            return true;
          case 'plugin.open_permission_setting':
            return true;
          case 'plugin.is_service_running':
            return true;
          case 'plugin.start_service':
            return true;
          case 'plugin.clean_cache':
            return true;
          case 'plugin.initialize':
            return {
              'permission_grated': true,
              'service_running': true,
              'windows': [],
            };
          case 'plugin.sync_windows':
            return [
              {
                'id': 'window-1',
                'config': {'entry': 'main', 'route': '/test'},
              },
              {
                'id': 'window-2',
                'config': {'entry': 'main', 'route': '/test2'},
              },
            ];
          case 'plugin.create_window':
            return {
              'id': methodCall.arguments['id'] ?? 'default',
              'config': methodCall.arguments['config'],
            };
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('should be a singleton', () {
      final plugin1 = FloatwingPlugin();
      final plugin2 = FloatwingPlugin();

      expect(identical(plugin1, plugin2), isTrue);
    });

    test('instance getter should return same instance', () {
      final plugin = FloatwingPlugin();

      expect(identical(plugin, plugin.instance), isTrue);
    });

    test('checkPermission should return true', () async {
      final result = await FloatwingPlugin().checkPermission();

      expect(result, isTrue);
    });

    test('openPermissionSetting should return true', () async {
      final result = await FloatwingPlugin().openPermissionSetting();

      expect(result, isTrue);
    });

    test('isServiceRunning should return true', () async {
      final result = await FloatwingPlugin().isServiceRunning();

      expect(result, isTrue);
    });

    test('startService should return true', () async {
      final result = await FloatwingPlugin().startService();

      expect(result, isTrue);
    });

    test('cleanCache should return true', () async {
      final result = await FloatwingPlugin().cleanCache();

      expect(result, isTrue);
    });

    test('syncWindows should populate windows map', () async {
      // Clear any existing state
      FloatwingPlugin().windows.clear();

      final result = await FloatwingPlugin().syncWindows();

      expect(result, isTrue);
      expect(FloatwingPlugin().windows.length, equals(2));
      expect(FloatwingPlugin().windows.containsKey('window-1'), isTrue);
      expect(FloatwingPlugin().windows.containsKey('window-2'), isTrue);
    });

    test('windows should return map of windows', () {
      final windows = FloatwingPlugin().windows;

      expect(windows, isA<Map<String, Window>>());
    });

    test('currentWindow should be null initially for main engine', () {
      // In main engine, currentWindow should be null until ensureWindow is called
      // Since we're testing as main engine, this is expected behavior
      expect(FloatwingPlugin().currentWindow, isNull);
    });

    test('isWindow should be false for main engine', () {
      // isWindow is false until ensureWindow succeeds with valid data
      // For main engine tests, this should be false
      expect(FloatwingPlugin().isWindow, isFalse);
    });

    test('createWindow should create and cache window', () async {
      final config = WindowConfig(route: '/new-window');

      final window = await FloatwingPlugin().createWindow('new-window', config);

      expect(window, isNotNull);
      expect(window?.id, equals('new-window'));
      expect(FloatwingPlugin().windows.containsKey('new-window'), isTrue);
    });

    test('createWindow with start=true should create started window', () async {
      final config = WindowConfig(route: '/started-window');

      final window = await FloatwingPlugin()
          .createWindow('started-window', config, start: true);

      expect(window, isNotNull);
      expect(window?.id, equals('started-window'));
    });

    test('on should return plugin for chaining', () {
      final plugin = FloatwingPlugin();

      final result = plugin.on(EventType.WindowCreated, (window, data) {});

      expect(result, same(plugin));
    });
  });

  group('FloatwingPlugin channel constants', () {
    test('channelID should be correct', () {
      expect(
          FloatwingPlugin.channelID, equals('im.zoe.labs/flutter_floatwing'));
    });
  });

  group('FloatwingPlugin permission flow', () {
    const MethodChannel methodChannel =
        MethodChannel('im.zoe.labs/flutter_floatwing/method');

    test('should handle permission denied', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel,
              (MethodCall methodCall) async {
        if (methodCall.method == 'plugin.has_permission') {
          return false;
        }
        return null;
      });

      final result = await FloatwingPlugin().checkPermission();

      expect(result, isFalse);

      // Cleanup
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('createWindow should throw when permission denied', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel,
              (MethodCall methodCall) async {
        if (methodCall.method == 'plugin.has_permission') {
          return false;
        }
        return null;
      });

      final config = WindowConfig(route: '/test');

      expect(
        () => FloatwingPlugin().createWindow('test', config),
        throwsException,
      );

      // Cleanup
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });
  });
}
