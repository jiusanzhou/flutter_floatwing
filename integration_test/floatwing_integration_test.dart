// Integration tests for flutter_floatwing plugin
//
// These tests simulate end-to-end workflows by mocking the native layer.
// Since flutter_floatwing requires Android-specific features (SYSTEM_ALERT_WINDOW),
// true integration testing requires running on an actual Android device.
//
// These tests verify the Dart layer integration works correctly.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end workflow tests', () {
    const MethodChannel methodChannel =
        MethodChannel('im.zoe.labs/flutter_floatwing/method');
    const MethodChannel windowChannel =
        MethodChannel('im.zoe.labs/flutter_floatwing/window');

    // Track method calls for verification
    final List<String> methodCalls = [];

    setUp(() {
      methodCalls.clear();

      // Mock main plugin channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel,
              (MethodCall methodCall) async {
        methodCalls.add(methodCall.method);

        switch (methodCall.method) {
          case 'plugin.has_permission':
            return true;
          case 'plugin.open_permission_setting':
            return true;
          case 'plugin.is_service_running':
            return false; // Start as not running
          case 'plugin.start_service':
            return true;
          case 'plugin.initialize':
            return {
              'permission_grated': true,
              'service_running': true,
              'windows': [],
            };
          case 'plugin.sync_windows':
            return [];
          case 'plugin.create_window':
            final id = methodCall.arguments['id'] ?? 'default';
            final config = methodCall.arguments['config'];
            return {
              'id': id,
              'pixelRadio': 2.0,
              'config': config,
            };
          default:
            return null;
        }
      });

      // Mock window channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(windowChannel,
              (MethodCall methodCall) async {
        methodCalls.add(methodCall.method);

        switch (methodCall.method) {
          case 'window.start':
            return true;
          case 'window.show':
            return true;
          case 'window.close':
            return true;
          case 'window.update':
            return {
              'id': methodCall.arguments['id'],
              'config': methodCall.arguments['config'],
            };
          case 'data.share':
            return {'received': true};
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(windowChannel, null);
    });

    test('Complete window creation workflow', () async {
      final plugin = FloatwingPlugin();

      // Step 1: Check permission
      final hasPermission = await plugin.checkPermission();
      expect(hasPermission, isTrue);
      expect(methodCalls, contains('plugin.has_permission'));

      // Step 2: Create window config
      final config = WindowConfig(
        id: 'test-overlay',
        route: '/overlay',
        width: 200,
        height: 100,
        draggable: true,
        gravity: GravityType.RightBottom,
      );

      // Step 3: Create and start window
      final window =
          await plugin.createWindow('test-overlay', config, start: true);

      expect(window, isNotNull);
      expect(window?.id, equals('test-overlay'));
      expect(methodCalls, contains('plugin.create_window'));
    });

    test('Window lifecycle workflow', () async {
      final plugin = FloatwingPlugin();

      // Create window
      final config = WindowConfig(route: '/test');
      final window = await plugin.createWindow('lifecycle-test', config);
      expect(window, isNotNull);

      // Start window
      final started = await window?.start();
      expect(started, isTrue);
      expect(methodCalls, contains('window.start'));

      // Show/hide window
      final shown = await window?.show(visible: true);
      expect(shown, isTrue);
      expect(methodCalls, contains('window.show'));

      final hidden = await window?.hide();
      expect(hidden, isTrue);

      // Close window
      final closed = await window?.close();
      expect(closed, isTrue);
      expect(methodCalls, contains('window.close'));
    });

    test('Window update workflow', () async {
      final plugin = FloatwingPlugin();

      // Create window
      final config = WindowConfig(
        route: '/update-test',
        width: 100,
        height: 100,
      );
      final window = await plugin.createWindow('update-test', config);
      expect(window, isNotNull);

      // Update window position
      final updateResult = await window?.update(WindowConfig(
        x: 50,
        y: 100,
        gravity: GravityType.Center,
      ));
      expect(updateResult, isTrue);
      expect(methodCalls, contains('window.update'));
    });

    test('Data sharing workflow', () async {
      final plugin = FloatwingPlugin();

      // Create window
      final config = WindowConfig(route: '/share-test');
      final window = await plugin.createWindow('share-test', config);
      expect(window, isNotNull);

      // Share data with window
      final shareResult = await window?.share(
        {'message': 'Hello from main app!'},
        name: 'greeting',
      );
      expect(shareResult, isNotNull);
      expect(methodCalls, contains('data.share'));
    });

    test('Event registration workflow', () async {
      final plugin = FloatwingPlugin();

      // Create window
      final config = WindowConfig(route: '/event-test');
      final window = await plugin.createWindow('event-test', config);
      expect(window, isNotNull);

      // Register event handlers
      window?.on(EventType.WindowCreated, (w, data) {
        // Handle created
      }).on(EventType.WindowStarted, (w, data) {
        // Handle started
      }).on(EventType.WindowDestroy, (w, data) {
        // Handle destroy
      }).on(EventType.WindowDragging, (w, data) {
        // Handle dragging
      });

      // Verify chaining works
      expect(window, isNotNull);
    });

    test('WindowConfig to Window workflow using to()', () async {
      // Using the fluent API
      final window = WindowConfig(
        id: 'fluent-test',
        route: '/fluent',
        width: 150,
        height: 150,
        draggable: true,
        clickable: true,
      ).to();

      expect(window, isNotNull);
      expect(window.id, equals('fluent-test'));
      expect(window.config?.route, equals('/fluent'));
      expect(window.config?.width, equals(150));
      expect(window.config?.draggable, isTrue);

      // Register events before creating
      window
          .on(EventType.WindowCreated, (w, data) {})
          .on(EventType.WindowStarted, (w, data) {});

      // Now create - this would actually create the window
      final created = await window.create(start: true);
      expect(created, isNotNull);
    });

    test('Multiple windows workflow', () async {
      final plugin = FloatwingPlugin();

      // Clear any existing windows
      plugin.windows.clear();

      // Create multiple windows
      final window1 = await plugin.createWindow(
        'window-1',
        WindowConfig(route: '/window1'),
      );
      final window2 = await plugin.createWindow(
        'window-2',
        WindowConfig(route: '/window2'),
      );
      final window3 = await plugin.createWindow(
        'window-3',
        WindowConfig(route: '/window3'),
      );

      expect(window1, isNotNull);
      expect(window2, isNotNull);
      expect(window3, isNotNull);

      // Verify all windows are cached
      expect(plugin.windows.length, equals(3));
      expect(plugin.windows.containsKey('window-1'), isTrue);
      expect(plugin.windows.containsKey('window-2'), isTrue);
      expect(plugin.windows.containsKey('window-3'), isTrue);

      // Close windows
      await window1?.close();
      await window2?.close();
      await window3?.close();
    });
  });

  group('Error handling integration tests', () {
    const MethodChannel methodChannel =
        MethodChannel('im.zoe.labs/flutter_floatwing/method');

    test('Should handle permission denied gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel,
              (MethodCall methodCall) async {
        if (methodCall.method == 'plugin.has_permission') {
          return false;
        }
        return null;
      });

      final plugin = FloatwingPlugin();
      final hasPermission = await plugin.checkPermission();

      expect(hasPermission, isFalse);

      // Cleanup
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('Should throw when creating window without permission', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel,
              (MethodCall methodCall) async {
        if (methodCall.method == 'plugin.has_permission') {
          return false;
        }
        return null;
      });

      final plugin = FloatwingPlugin();
      final config = WindowConfig(route: '/test');

      expect(
        () => plugin.createWindow('no-permission', config),
        throwsException,
      );

      // Cleanup
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });
  });

  group('Configuration combinations', () {
    test('Full-screen overlay config (night mode style)', () {
      final config = WindowConfig(
        id: 'night-mode',
        route: '/night',
        width: WindowSize.MatchParent,
        height: WindowSize.MatchParent,
        clickable: false, // Touch passes through
        focusable: false,
      );

      expect(config.width, equals(WindowSize.MatchParent));
      expect(config.height, equals(WindowSize.MatchParent));
      expect(config.clickable, isFalse);
      expect(config.focusable, isFalse);
    });

    test('Floating button config (assistive touch style)', () {
      final config = WindowConfig(
        id: 'float-button',
        route: '/button',
        width: 56,
        height: 56,
        draggable: true,
        gravity: GravityType.RightBottom,
        autosize: true,
      );

      expect(config.width, equals(56));
      expect(config.height, equals(56));
      expect(config.draggable, isTrue);
      expect(config.gravity, equals(GravityType.RightBottom));
      expect(config.autosize, isTrue);
    });

    test('Popup config', () {
      final config = WindowConfig(
        id: 'popup',
        route: '/popup',
        width: 300,
        height: 200,
        gravity: GravityType.Center,
        clickable: true,
        focusable: true,
        draggable: false,
      );

      expect(config.gravity, equals(GravityType.Center));
      expect(config.clickable, isTrue);
      expect(config.focusable, isTrue);
      expect(config.draggable, isFalse);
    });

    test('All gravity types should be distinct', () {
      final gravities = [
        GravityType.Center,
        GravityType.CenterTop,
        GravityType.CenterBottom,
        GravityType.LeftTop,
        GravityType.LeftCenter,
        GravityType.LeftBottom,
        GravityType.RightTop,
        GravityType.RightCenter,
        GravityType.RightBottom,
      ];

      // All should have unique int values
      final intValues = gravities.map((g) => g.toInt()).toSet();
      expect(intValues.length, equals(gravities.length));
    });
  });
}
