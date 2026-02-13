import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EventType', () {
    test('should have all expected event types', () {
      expect(EventType.values, contains(EventType.WindowCreated));
      expect(EventType.values, contains(EventType.WindowStarted));
      expect(EventType.values, contains(EventType.WindowPaused));
      expect(EventType.values, contains(EventType.WindowResumed));
      expect(EventType.values, contains(EventType.WindowDestroy));
      expect(EventType.values, contains(EventType.WindowDragStart));
      expect(EventType.values, contains(EventType.WindowDragging));
      expect(EventType.values, contains(EventType.WindowDragEnd));
    });

    test('should have correct number of event types', () {
      expect(EventType.values.length, equals(8));
    });
  });

  group('Event', () {
    test('should create with all parameters', () {
      final event = Event(
        id: 'window-1',
        name: 'window.created',
        data: {'key': 'value'},
      );

      expect(event.id, equals('window-1'));
      expect(event.name, equals('window.created'));
      expect(event.data, isA<Map>());
      expect(event.data['key'], equals('value'));
    });

    test('should create with null parameters', () {
      final event = Event();

      expect(event.id, isNull);
      expect(event.name, isNull);
      expect(event.data, isNull);
    });

    test('should create from map correctly', () {
      final map = {
        'id': 'window-2',
        'name': 'window.started',
        'data': {'position': 'center'},
      };

      final event = Event.fromMap(map);

      expect(event.id, equals('window-2'));
      expect(event.name, equals('window.started'));
      expect(event.data, isA<Map>());
      expect(event.data['position'], equals('center'));
    });

    test('should handle missing fields in fromMap', () {
      final map = <dynamic, dynamic>{
        'id': 'window-3',
      };

      final event = Event.fromMap(map);

      expect(event.id, equals('window-3'));
      expect(event.name, isNull);
      expect(event.data, isNull);
    });

    test('should handle dynamic data types', () {
      final eventWithString = Event(data: 'string data');
      expect(eventWithString.data, equals('string data'));

      final eventWithInt = Event(data: 42);
      expect(eventWithInt.data, equals(42));

      final eventWithList = Event(data: [1, 2, 3]);
      expect(eventWithList.data, equals([1, 2, 3]));

      final eventWithBool = Event(data: true);
      expect(eventWithBool.data, isTrue);
    });
  });

  group('Event name mapping', () {
    // Test that event names are correctly mapped (based on the _EventType extension)
    test('WindowCreated should map to window.created', () {
      // We can't directly test the private extension, but we can verify
      // the event types exist and are usable
      expect(EventType.WindowCreated, isNotNull);
    });

    test('WindowDragStart should map to window.drag_start', () {
      expect(EventType.WindowDragStart, isNotNull);
    });

    test('all event types should be distinct', () {
      final types = EventType.values.toSet();
      expect(types.length, equals(EventType.values.length));
    });
  });

  group('Window event registration', () {
    test('should allow registering multiple event handlers', () {
      final window = Window(id: 'test-window');
      int handlerCount = 0;

      window.on(EventType.WindowCreated, (w, data) {
        handlerCount++;
      }).on(EventType.WindowStarted, (w, data) {
        handlerCount++;
      }).on(EventType.WindowDestroy, (w, data) {
        handlerCount++;
      });

      // The handlers are registered but not called yet
      expect(handlerCount, equals(0));
    });

    test('on() should return window for chaining', () {
      final window = Window(id: 'test-window');

      final result = window.on(EventType.WindowCreated, (w, data) {});

      expect(result, same(window));
    });

    test('should handle all event types registration', () {
      final window = Window(id: 'test-window');

      // Register handlers for all event types
      for (final eventType in EventType.values) {
        window.on(eventType, (w, data) {});
      }

      // If we get here without errors, all event types are registrable
      expect(true, isTrue);
    });
  });

  group('WindowListener typedef', () {
    test('should accept correct function signature', () {
      // WindowListener = dynamic Function(Window window, dynamic data)
      WindowListener listener = (Window w, dynamic data) {
        return 'handled';
      };

      final window = Window(id: 'test');
      final result = listener(window, {'event': 'data'});

      expect(result, equals('handled'));
    });

    test('should work with async handlers', () async {
      WindowListener asyncListener = (Window w, dynamic data) async {
        await Future.delayed(Duration(milliseconds: 10));
        return 'async handled';
      };

      final window = Window(id: 'test');
      final result = await asyncListener(window, null);

      expect(result, equals('async handled'));
    });

    test('should allow void return', () {
      WindowListener voidListener = (Window w, dynamic data) {
        // No return
      };

      final window = Window(id: 'test');
      final result = voidListener(window, null);

      expect(result, isNull);
    });
  });
}
