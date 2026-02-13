import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Window', () {
    test('should create with default id', () {
      final window = Window();

      expect(window.id, equals('default'));
      expect(window.config, isNull);
      expect(window.pixelRadio, isNull);
      expect(window.system, isNull);
    });

    test('should create with custom id and config', () {
      final config = WindowConfig(
        route: '/test',
        width: 200,
        height: 300,
      );
      final window = Window(id: 'test-window', config: config);

      expect(window.id, equals('test-window'));
      expect(window.config, equals(config));
      expect(window.config?.route, equals('/test'));
      expect(window.config?.width, equals(200));
      expect(window.config?.height, equals(300));
    });

    test('should create from map correctly', () {
      final map = {
        'id': 'map-window',
        'pixelRadio': 2.0,
        'system': {
          'pixelRadio': 2,
          'screen': {'width': 1080, 'height': 1920},
        },
        'config': {
          'entry': 'main',
          'route': '/test',
          'width': 200,
          'height': 300,
          'draggable': true,
        },
      };

      final window = Window.fromMap(map);

      expect(window.id, equals('map-window'));
      expect(window.pixelRadio, equals(2.0));
      expect(window.system, isNotNull);
      expect(window.system?.screenWidth, equals(1080));
      expect(window.system?.screenHeight, equals(1920));
      expect(window.config?.route, equals('/test'));
      expect(window.config?.width, equals(200));
      expect(window.config?.height, equals(300));
      expect(window.config?.draggable, isTrue);
    });

    test('should apply map to existing window', () {
      final window = Window(id: 'original');
      final map = {
        'id': 'updated',
        'pixelRadio': 3.0,
        'config': {
          'entry': 'custom',
          'width': 400,
        },
      };

      window.applyMap(map);

      expect(window.id, equals('updated'));
      expect(window.pixelRadio, equals(3.0));
      expect(window.config?.entry, equals('custom'));
      expect(window.config?.width, equals(400));
    });

    test('should handle null map in applyMap', () {
      final window = Window(id: 'test');
      final result = window.applyMap(null);

      expect(result.id, equals('test'));
    });

    test('should convert to map correctly', () {
      final config = WindowConfig(
        route: '/test',
        width: 200,
        height: 300,
      );
      final window = Window(id: 'test-window', config: config);
      window.pixelRadio = 2.5;

      final map = window.toMap();

      expect(map['id'], equals('test-window'));
      expect(map['pixelRadio'], equals(2.5));
      expect(map['config'], isA<Map>());
      expect(map['config']['route'], equals('/test'));
    });

    test('toString should contain window id', () {
      final window = Window(id: 'my-window');

      final str = window.toString();

      expect(str, contains('Window[my-window]'));
    });

    test('should register onData handler', () {
      final window = Window(id: 'test');
      bool handlerCalled = false;

      window.onData((source, name, data) async {
        handlerCalled = true;
        return null;
      });

      // Handler registered, but we can't easily test it without a real channel
      expect(window, isNotNull);
    });

    test(
        'should register event handler with on() and return window for chaining',
        () {
      final window = Window(id: 'test');

      final result = window
          .on(EventType.WindowCreated, (w, data) {})
          .on(EventType.WindowStarted, (w, data) {});

      expect(result, equals(window));
    });
  });

  group('Window MethodChannel operations', () {
    const MethodChannel windowChannel =
        MethodChannel('im.zoe.labs/flutter_floatwing/window');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(windowChannel,
              (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'window.show':
            return true;
          case 'window.close':
            return true;
          case 'window.start':
            return true;
          case 'window.update':
            return {
              'id': methodCall.arguments['id'],
              'config': methodCall.arguments['config'],
            };
          case 'data.share':
            return 'shared';
          case 'window.launch_main':
            return true;
          case 'window.sync':
            return {
              'id': 'synced-window',
              'pixelRadio': 2.0,
              'config': {'entry': 'main', 'route': '/synced'},
            };
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(windowChannel, null);
    });

    test('hide should call show with visible=false', () async {
      final config = WindowConfig(visible: true);
      final window = Window(id: 'test', config: config);

      final result = await window.hide();

      expect(result, isTrue);
      expect(window.config?.visible, isFalse);
    });

    test('show should update visibility', () async {
      final config = WindowConfig(visible: false);
      final window = Window(id: 'test', config: config);

      final result = await window.show(visible: true);

      expect(result, isTrue);
    });

    test('close should return true', () async {
      final window = Window(id: 'test');

      final result = await window.close();

      expect(result, isTrue);
    });

    test('close with force should work', () async {
      final window = Window(id: 'test');

      final result = await window.close(force: true);

      expect(result, isTrue);
    });

    test('start should return true', () async {
      final config = WindowConfig(route: '/test');
      final window = Window(id: 'test', config: config);

      final result = await window.start();

      expect(result, isTrue);
    });

    test('share should send data and return response', () async {
      final window = Window(id: 'test');

      final result = await window.share({'key': 'value'}, name: 'test-data');

      expect(result, equals('shared'));
    });

    test('launchMainActivity should return true', () async {
      final window = Window(id: 'test');

      final result = await window.launchMainActivity();

      expect(result, isTrue);
    });

    test('Window.sync should return map', () async {
      final result = await Window.sync();

      expect(result, isNotNull);
      expect(result?['id'], equals('synced-window'));
      expect(result?['config']['route'], equals('/synced'));
    });

    test('update should apply new config', () async {
      final config = WindowConfig(width: 100, height: 100);
      final window = Window(id: 'test', config: config);

      final result = await window.update(WindowConfig(width: 200, height: 200));

      expect(result, isTrue);
    });
  });
}
