import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

void main() {
  group('WindowConfig', () {
    test('should create with default values', () {
      final config = WindowConfig();

      expect(config.id, equals('default'));
      expect(config.entry, equals('main'));
      expect(config.route, isNull);
      expect(config.callback, isNull);
      expect(config.width, isNull);
      expect(config.height, isNull);
      expect(config.x, isNull);
      expect(config.y, isNull);
      expect(config.autosize, isNull);
      expect(config.gravity, isNull);
      expect(config.clickable, isNull);
      expect(config.draggable, isNull);
      expect(config.focusable, isNull);
      expect(config.immersion, isNull);
      expect(config.visible, isNull);
    });

    test('should create with custom values', () {
      final config = WindowConfig(
        id: 'test-window',
        entry: 'customEntry',
        route: '/test',
        width: 200,
        height: 300,
        x: 10,
        y: 20,
        autosize: true,
        gravity: GravityType.Center,
        clickable: true,
        draggable: true,
        focusable: false,
        immersion: true,
        visible: true,
      );

      expect(config.id, equals('test-window'));
      expect(config.entry, equals('customEntry'));
      expect(config.route, equals('/test'));
      expect(config.width, equals(200));
      expect(config.height, equals(300));
      expect(config.x, equals(10));
      expect(config.y, equals(20));
      expect(config.autosize, isTrue);
      expect(config.gravity, equals(GravityType.Center));
      expect(config.clickable, isTrue);
      expect(config.draggable, isTrue);
      expect(config.focusable, isFalse);
      expect(config.immersion, isTrue);
      expect(config.visible, isTrue);
    });

    test('should convert to map correctly', () {
      final config = WindowConfig(
        id: 'test-window',
        route: '/test',
        width: 200,
        height: 300,
        draggable: true,
      );

      final map = config.toMap();

      expect(map['entry'], equals('main'));
      expect(map['route'], equals('/test'));
      expect(map['width'], equals(200));
      expect(map['height'], equals(300));
      expect(map['draggable'], isTrue);
    });

    test('should create from map correctly', () {
      final map = {
        'entry': 'customEntry',
        'route': '/test',
        'width': 200,
        'height': 300,
        'x': 10,
        'y': 20,
        'autosize': true,
        'clickable': true,
        'draggable': true,
        'focusable': false,
        'immersion': true,
        'visible': true,
      };

      final config = WindowConfig.fromMap(map);

      expect(config.entry, equals('customEntry'));
      expect(config.route, equals('/test'));
      expect(config.width, equals(200));
      expect(config.height, equals(300));
      expect(config.x, equals(10));
      expect(config.y, equals(20));
      expect(config.autosize, isTrue);
      expect(config.clickable, isTrue);
      expect(config.draggable, isTrue);
      expect(config.focusable, isFalse);
      expect(config.immersion, isTrue);
      expect(config.visible, isTrue);
    });

    test('should return correct size', () {
      final config = WindowConfig(width: 200, height: 300);

      expect(config.size.width, equals(200.0));
      expect(config.size.height, equals(300.0));
    });

    test('should return zero size when dimensions are null', () {
      final config = WindowConfig();

      expect(config.size.width, equals(0.0));
      expect(config.size.height, equals(0.0));
    });

    test('should convert to Window using to()', () {
      final config = WindowConfig(id: 'test-window', route: '/test');
      final window = config.to();

      expect(window, isA<Window>());
      expect(window.id, equals('test-window'));
      expect(window.config, equals(config));
    });

    test('toString should return JSON representation', () {
      final config = WindowConfig(
        route: '/test',
        width: 200,
        draggable: true,
      );

      final str = config.toString();

      expect(str, contains('route'));
      expect(str, contains('/test'));
      expect(str, contains('width'));
      expect(str, contains('200'));
      expect(str, contains('draggable'));
      expect(str, contains('true'));
    });
  });

  group('WindowSize', () {
    test('should have correct constant values', () {
      expect(WindowSize.MatchParent, equals(-1));
      expect(WindowSize.WrapContent, equals(-2));
    });
  });

  group('GravityType', () {
    test('should convert to int correctly', () {
      expect(GravityType.Center.toInt(), isNotNull);
      expect(GravityType.LeftTop.toInt(), isNotNull);
      expect(GravityType.RightBottom.toInt(), isNotNull);
    });

    test('should convert from int correctly', () {
      final centerInt = GravityType.Center.toInt();
      final result = GravityType.Unknown.fromInt(centerInt);

      expect(result, equals(GravityType.Center));
    });

    test('should return null for unknown int', () {
      final result = GravityType.Unknown.fromInt(999);

      expect(result, isNull);
    });

    test('should return null for null int', () {
      final result = GravityType.Unknown.fromInt(null);

      expect(result, isNull);
    });

    test('all gravity types should have valid int values', () {
      for (final gravity in GravityType.values) {
        if (gravity != GravityType.Unknown) {
          expect(gravity.toInt(), isNotNull,
              reason: '$gravity should have a valid int value');
        }
      }
    });
  });
}
