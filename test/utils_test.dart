import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_floatwing/src/utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SystemConfig', () {
    test('should create from map correctly', () {
      final map = {
        'pixelRadio': 2,
        'screen': {
          'width': 1080,
          'height': 1920,
        },
      };

      final config = SystemConfig.fromMap(map);

      expect(config.pixelRadio, equals(2));
      expect(config.screenWidth, equals(1080));
      expect(config.screenHeight, equals(1920));
      expect(config.screenSize, isNotNull);
      expect(config.screenSize?.width, equals(1080.0));
      expect(config.screenSize?.height, equals(1920.0));
    });

    test('should handle missing screen data', () {
      final map = {
        'pixelRadio': 3,
      };

      final config = SystemConfig.fromMap(map);

      expect(config.pixelRadio, equals(3));
      expect(config.screenWidth, isNull);
      expect(config.screenHeight, isNull);
      expect(config.screenSize, isNull);
    });

    test('should handle empty map', () {
      final config = SystemConfig.fromMap({});

      expect(config.pixelRadio, isNull);
      expect(config.screenWidth, isNull);
      expect(config.screenHeight, isNull);
      expect(config.screenSize, isNull);
    });

    test('should convert to map correctly', () {
      final map = {
        'pixelRadio': 2,
        'screen': {
          'width': 1080,
          'height': 1920,
        },
      };

      final config = SystemConfig.fromMap(map);
      final result = config.toMap();

      expect(result['pixelRadio'], equals(2));
      expect(result['screen'], isA<Map>());
      expect(result['screen']['width'], equals(1080));
      expect(result['screen']['height'], equals(1920));
    });

    test('toString should return map and size representation', () {
      final map = {
        'pixelRadio': 2,
        'screen': {
          'width': 1080,
          'height': 1920,
        },
      };

      final config = SystemConfig.fromMap(map);
      final str = config.toString();

      expect(str, contains('pixelRadio'));
      expect(str, contains('1080'));
      expect(str, contains('1920'));
    });

    test('should create Size object only when both dimensions are present', () {
      // Both dimensions present
      final config1 = SystemConfig.fromMap({
        'screen': {'width': 100, 'height': 200},
      });
      expect(config1.screenSize, isNotNull);

      // Only width present
      final config2 = SystemConfig.fromMap({
        'screen': {'width': 100},
      });
      expect(config2.screenSize, isNull);

      // Only height present
      final config3 = SystemConfig.fromMap({
        'screen': {'height': 200},
      });
      expect(config3.screenSize, isNull);

      // Neither present
      final config4 = SystemConfig.fromMap({
        'screen': {},
      });
      expect(config4.screenSize, isNull);
    });

    test('should preserve exact values through toMap', () {
      final originalMap = {
        'pixelRadio': 3,
        'screen': {
          'width': 2560,
          'height': 1440,
        },
      };

      final config = SystemConfig.fromMap(originalMap);
      final resultMap = config.toMap();

      expect(resultMap['pixelRadio'], equals(originalMap['pixelRadio']));
      final originalScreen = originalMap['screen'] as Map<String, dynamic>;
      final resultScreen = resultMap['screen'] as Map<dynamic, dynamic>;
      expect(
        resultScreen['width'],
        equals(originalScreen['width']),
      );
      expect(
        resultScreen['height'],
        equals(originalScreen['height']),
      );
    });
  });
}
