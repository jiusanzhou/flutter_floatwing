<div align="center">

# flutter_floatwing

[![Pub Version](https://img.shields.io/pub/v/flutter_floatwing?color=blue&logo=dart)](https://pub.dev/packages/flutter_floatwing)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android-green.svg)](https://flutter.dev)

A Flutter plugin that makes it easier to create floating/overlay windows for Android with pure Flutter. **Android only**

</div>

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🎨 **Pure Flutter** | Write your entire overlay window in pure Flutter |
| 🚀 **Simple** | Start your overlay window with as little as 1 line of code |
| 📐 **Auto Resize** | Just focus on your Flutter widget size — the Android view resizes automatically |
| 🪟 **Multi-window** | Create multiple overlay windows with parent-child relationships |
| 💬 **Communicable** | Main app and overlay windows can communicate seamlessly with each other |
| 📡 **Event Mechanism** | Subscribe to window lifecycle events and drag actions for flexible control |

*More features are coming...*

## 📸 Previews

| Night Mode | Simple Example | Assistive Touch |
|:----------:|:--------------:|:---------------:|
| ![Night mode](./assets/flutter-floatwing-example-1.gif) | ![Simple example](./assets/flutter-floatwing-example-2.gif) | ![Assistive touch](./assets/flutter-floatwing-example-3.gif) |

## 📦 Installation

Add `flutter_floatwing` to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter_floatwing: ^0.2.1
```

Then install it:
- **Terminal**: Run `flutter pub get`
- **Android Studio/IntelliJ**: Click "Packages get" in the action ribbon at the top of `pubspec.yaml`
- **VS Code**: Click "Get Packages" on the right side of the action ribbon at the top of `pubspec.yaml`

Or simply run:

```bash
flutter pub add flutter_floatwing
```

## 🚀 Quick Start

Since we use Android's system alert window for display, you need to add the permission to `AndroidManifest.xml` first:

```xml
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
```

Add a route for the widget that will be displayed in the overlay window:

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: "/",
    routes: {
      "/": (_) => HomePage(),
      // Add a route as the entry point for your overlay window
      "/my-overlay-window": (_) => MyOverlayWindow(),
    },
  );
}
```

Before starting the floating window, check and request permission, then initialize the `flutter_floatwing` plugin in `initState` or a button callback:

```dart
// Check and request the system alert window permission
FloatwingPlugin().checkPermission().then((granted) {
  if (!granted) FloatwingPlugin().openPermissionSetting();
});

// Initialize the plugin first
FloatwingPlugin().initialize();
```

Now create and start your overlay window:

```dart
// Define window config and start the window
WindowConfig(route: "/my-overlay-window")
    .to()           // Create a window object
    .create(start: true);  // Create and start the overlay window
```

---

**Notes:**

- `route` is one of 3 ways to define an entry point for the overlay window. See the [Entry Point](#-entry-point) section for more details.
- See the [Usage](#-usage) section for more features.

## 🏗️ Architecture

Before diving into how `flutter_floatwing` manages windows, here are some key concepts:

- **`id`** is the unique identifier for each window. All operations on a window are based on this `id` — you must provide one before creating a window.
- The first engine created when opening the main application is called the **main engine** (or **plugin engine**). Engines created by the service are called **window engines**.
- Different engines run in **different threads** and cannot communicate directly.
- You can subscribe to events from all windows in the main engine. In a window engine, you can subscribe to events from itself and its child windows, but not from sibling or parent windows.
- **`share` data** is the only way to communicate between engines. The only restriction is that the data must be serializable — you can share data from anywhere to anywhere.

A floatwing window object consists of a Flutter engine that runs a widget via `runApp` and a view that is added to the Android window manager.

![floatwing window](./assets/flutter-floatwing-window.png)

The overall view hierarchy looks like this:

![flutter floatwing architecture](./assets/flutter-floatwing-arch.png)

## 📖 Usage

Here's how `flutter_floatwing` creates a new overlay window:

1. Start a background service as the window manager from the main app.
2. Send a create window request to the service.
3. In the service, start a Flutter engine with the specified entry point.
4. Create a new Flutter view and attach it to the Flutter engine.
5. Add the view to the Android window manager.

### Window & Config

`WindowConfig` contains all configuration options for a window. You can create a window using configuration like this:

```dart
void _createWindow() {
  var config = WindowConfig();
  var w = Window(config, id: "my-window");
  w.create();
}
```

If you don't need to register event or data handlers, you can create a window directly from the config:

```dart
void _createWindow() {
  WindowConfig(id: "my-window").create();
}
```

Note that if you want to specify a window ID, you must provide it in `WindowConfig`.

If you want to register handlers, use the `to()` function to convert a config to a window first — this is useful for keeping your code clean:

```dart
void _createWindow() {
  WindowConfig(id: "my-window")
      .to()
      .on(EventType.WindowCreated, (w, _) {})
      .create();
}
```

#### Window Lifecycle

- created
- started
- paused
- resumed
- destroyed

### 🎯 Entry Point

The entry point determines where the engine starts execution. We support 3 configuration modes:

| Name | Config | How to Use |
|:-----|:-------|:-----------|
| `route` | `WindowConfig(route: "/my-overlay")` | Add a route for the overlay window in your main routes, then start with: `WindowConfig(route: "/my-overlay")` |
| `static function` | `WindowConfig(callback: myOverlayMain)` | Define a static `void Function()` that calls `runApp` to start a widget, then start with: `WindowConfig(callback: myOverlayMain)` |
| `entry-point` | `WindowConfig(entry: "myOverlayMain")` | Same as static function, but add `@pragma("vm:entry-point")` above the function and use the function name as a string: `WindowConfig(entry: "myOverlayMain")` |

#### Example: Using `route`

1. Add a route for your overlay widget in the main application:

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: "/",
    routes: {
      "/": (_) => HomePage(),
      // Add a route as the entry point for your overlay window
      "/my-overlay-window": (_) => MyOverlayWindow(),
    },
  );
}
```

2. Start the window with `route`:

```dart
void _startWindow() {
  WindowConfig(route: "/my-overlay-window")
      .to()
      .create(start: true);
}
```

#### Example: Using `static function`

1. Define a static function that calls `runApp`:

```dart
void myOverlayMain() {
  runApp(MaterialApp(
    home: AssistivePanel(),
  ));
  // Or use the floatwing helper to inject MaterialApp
  // runApp(AssistivePanel().floatwing(app: true));
}
```

2. Start the window with `callback`:

```dart
void _startWindow() {
  WindowConfig(callback: myOverlayMain)
      .to()
      .create(start: true);
}
```

#### Example: Using `entry-point`

1. Define a static function that calls `runApp` and add the pragma annotation:

```dart
@pragma("vm:entry-point")
void myOverlayMain() {
  runApp(MaterialApp(
    home: AssistivePanel(),
  ));
  // Or use the floatwing helper to inject MaterialApp
  // runApp(AssistivePanel().floatwing(app: true));
}
```

2. Start the window with `entry`:

```dart
void _startWindow() {
  WindowConfig(entry: "myOverlayMain")
      .to()
      .create(start: true);
}
```

### Wrapping Your Widget

For simple widgets, no special wrapping is needed. But if you want additional functionality and cleaner code, we provide an injector for your widget.

Current features include:
- Auto-resize the window view
- Auto-sync and ensure the window
- Wrap with `MaterialApp`
- *More features coming...*

Previously, you would write your overlay main function like this:

```dart
void overlayMain() {
  runApp(MaterialApp(
    home: MyOverlayView(),
  ));
}
```

Now you can simplify it to:

```dart
void overlayMain() {
  runApp(MyOverlayView().floatwing(app: true));
}
```

You can wrap both `Widget` and `WidgetBuilder`. When wrapping a `WidgetBuilder`, you can access the window instance using `Window.of(context)`. For wrapped `Widget`, use `FloatwingPlugin().currentWindow` instead.

To access the window via `Window.of(context)`, use this pattern:

```dart
void overlayMain() {
  runApp(((_) => MyOverlayView()).floatwing(app: true).make());
}
```

### Accessing Window in Overlay

In your window engine, you can access the window object in two ways:

- Directly access the plugin's cached field: `FloatwingPlugin().currentWindow`
- If the widget is wrapped with `.floatwing()`, use `Window.of(context)`

`FloatwingPlugin().currentWindow` returns `null` until initialization is complete.

If you inject a `WidgetBuilder` with `.floatwing()`, you can access the current window. It will always return a non-null value, unless you enable debug mode with `.floatwing(debug: true)`.

For example, to get the `id` of the current window:

```dart
import 'package:flutter_floatwing/flutter_floatwing.dart';

class _ExampleViewState extends State<ExampleView> {
  Window? w;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance?.addPostFrameCallback((_) {
      w = Window.of(context);
      print("My window ID is ${w?.id}");
    });
  }
}
```

### Subscribing to Events

You can subscribe to window events and trigger actions when they fire. Window events are sent to the main engine, the window's own engine, and the parent window engine. This means you can subscribe to window events from the main application, the overlay window itself, or the parent overlay window.

Currently supported events include window lifecycle and drag actions:

```dart
enum EventType {
  WindowCreated,
  WindowStarted,
  WindowPaused,
  WindowResumed,
  WindowDestroy,

  WindowDragStart,
  WindowDragging,
  WindowDragEnd,
}
```

*More event types are coming — contributions are welcome!*

For example, to perform an action when a window starts:

```dart
@override
void initState() {
  super.initState();

  SchedulerBinding.instance?.addPostFrameCallback((_) {
    w = Window.of(context);
    w?.on(EventType.WindowStarted, (window, _) {
      print("$w has started.");
    }).on(EventType.WindowDestroy, (window, data) {
      // data is a boolean indicating whether the window was force-closed
      print("$w has been destroyed, force: $data");
    });
  });
}
```

### Sharing Data with Windows

Sharing data is the only way to communicate with windows. Use `window.share(data)` for this purpose.

For example, to share data from the main application to an overlay window:

First, get the target window in the main application (either the one you created or from the `windows` cache by ID):

```dart
Window w;

void _startWindow() {
  w = WindowConfig(route: "/my-overlay-window").to();
}

void _shareData(dynamic data) {
  w.share(data).then((value) {
    // The window can return a value
  });
  // Or get the window from cache
  // FloatwingPlugin().windows["default"]?.share(data);
}
```

To share data with a specific name, add the name parameter: `w.share(data, name: "name-1")`.

Then register a data handler in the window to receive the data:

```dart
@override
void initState() {
  super.initState();

  SchedulerBinding.instance?.addPostFrameCallback((_) {
    w = Window.of(context);
    w?.onData((source, name, data) async {
      print("Received $name data from $source: $data");
    });
  });
}
```

The handler function signature is `Future<dynamic> Function(String? source, String? name, dynamic data)`:

- `source`: Where the data comes from. `null` if from the main application; otherwise, the `id` of the source window.
- `name`: The data name, useful for sharing data for different purposes.
- `data`: The actual data received.
- Return a value if you want to respond.

You can send data to any window as long as you know its ID — the only restriction is that you cannot send data to yourself. *Note: Sharing data to the main application is not yet implemented.*

**Important: The data you share must be serializable.**

## 📚 API Reference

### FloatwingPlugin

```dart
FloatwingPlugin()
  // Permission
  ..checkPermission()       // Check overlay permission → Future<bool>
  ..openPermissionSetting() // Open system settings → Future<bool>
  
  // Initialization
  ..initialize()            // Initialize the plugin → Future<bool>
  
  // Service Management
  ..isServiceRunning()      // Check if background service is running → Future<bool>
  ..startService()          // Start the background service → Future<bool>
  ..syncWindows()           // Sync windows from service → Future<bool>
  ..cleanCache()            // Clean cached data → Future<bool>
  
  // Window Access
  ..currentWindow           // Get current window (in overlay) → Window?
  ..windows                 // Map of all windows by ID → Map<String, Window>
  ..isWindow                // Check if running in window engine → bool
```

`FloatwingPlugin` is a singleton class that returns the same instance every time you call the `FloatwingPlugin()` factory method.

### WindowConfig

Complete configuration options for overlay windows:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | `String` | `"default"` | Unique window identifier |
| `entry` | `String` | `"main"` | Entry point function name |
| `route` | `String?` | `null` | Flutter route for the window |
| `callback` | `Function?` | `null` | Static function to run (must be static) |
| `width` | `int?` | `null` | Window width in pixels |
| `height` | `int?` | `null` | Window height in pixels |
| `x` | `int?` | `null` | X position on screen |
| `y` | `int?` | `null` | Y position on screen |
| `autosize` | `bool?` | `null` | Auto-resize to fit content |
| `gravity` | `GravityType?` | `null` | Window position alignment |
| `clickable` | `bool?` | `null` | Allow click-through when `false` |
| `draggable` | `bool?` | `null` | Enable drag to move |
| `focusable` | `bool?` | `null` | Allow window to receive focus |
| `immersion` | `bool?` | `null` | Immersive status bar mode |
| `visible` | `bool?` | `null` | Initial visibility state |

#### WindowSize Constants

```dart
WindowSize.MatchParent  // -1: Fill entire screen
WindowSize.WrapContent  // -2: Fit to content size
```

#### GravityType Enum

```dart
GravityType.Center        // Center of screen
GravityType.CenterTop     // Top center
GravityType.CenterBottom  // Bottom center
GravityType.LeftTop       // Top left corner
GravityType.LeftCenter    // Left center
GravityType.LeftBottom    // Bottom left corner
GravityType.RightTop      // Top right corner
GravityType.RightCenter   // Right center
GravityType.RightBottom   // Bottom right corner
```

**Example — Full-screen non-clickable overlay (night mode):**

```dart
WindowConfig(
  id: "night-mode",
  route: "/night",
  width: WindowSize.MatchParent,
  height: WindowSize.MatchParent,
  clickable: false,  // Touch passes through
)
```

**Example — Draggable floating button:**

```dart
WindowConfig(
  id: "float-button",
  route: "/button",
  draggable: true,
  gravity: GravityType.RightBottom,
)
```

### Window

| Method | Returns | Description |
|--------|---------|-------------|
| `create({start: bool})` | `Future<Window?>` | Create window, optionally start immediately |
| `start()` | `Future<bool?>` | Start/show the window |
| `close({force: bool})` | `Future<bool?>` | Close the window |
| `show({visible: bool})` | `Future<bool?>` | Show or hide the window |
| `hide()` | `Future<bool?>` | Hide the window (shortcut for `show(visible: false)`) |
| `update(WindowConfig)` | `Future<bool>` | Update window configuration |
| `share(data, {name})` | `Future<dynamic>` | Send data to this window |
| `on(EventType, handler)` | `Window` | Subscribe to events (chainable) |
| `onData(handler)` | `Window` | Register data receive handler |
| `launchMainActivity()` | `Future<bool>` | Open main app from overlay |
| `createChildWindow(...)` | `Future<Window?>` | Create a child window (from overlay only) |

**Static Methods:**

| Method | Returns | Description |
|--------|---------|-------------|
| `Window.of(context)` | `Window?` | Get window instance from BuildContext |
| `Window.sync()` | `Future<Map?>` | Sync window state from Android |

### Child Windows

You can create nested windows from within an overlay:

```dart
// In your overlay window widget
final parentWindow = Window.of(context);

parentWindow?.createChildWindow(
  "child-popup",
  WindowConfig(
    route: "/popup",
    width: 200,
    height: 100,
  ),
  start: true,
);
```

## ❤️ Support

Did you find this plugin useful? Please consider making a donation to help improve it!

## 🔧 Troubleshooting

### Release Mode Error: "No top-level getter declared"

If you see this error in release mode when using `entry-point`:

```
NoSuchMethodError: No top-level getter 'xxx' declared.
Could not resolve main entrypoint function.
```

**Solution**: Make sure your entry point function is:

1. **Defined in `main.dart`** or imported into `main.dart`
2. **Marked with `@pragma("vm:entry-point")`** to prevent tree-shaking

```dart
// In main.dart
@pragma("vm:entry-point")
void myOverlayMain() {
  runApp(MyOverlayWidget().floatwing(app: true));
}
```

If defined in another file, import it in `main.dart`:

```dart
// main.dart
import 'package:myapp/overlay_entry.dart';  // Contains myOverlayMain

void main() {
  runApp(MyApp());
}

// Re-export to ensure it's included in the build
export 'package:myapp/overlay_entry.dart';
```

### Buttons Get Stuck Pressed When Dragging

If buttons inside a draggable overlay widget get stuck in pressed state when pressing and dragging simultaneously:

**Workaround**: Disable dragging while the button is pressed:

```dart
ElevatedButton(
  style: ButtonStyle(
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        Window.of(context)?.update(WindowConfig(draggable: false));
        return Colors.blue;
      } else {
        Window.of(context)?.update(WindowConfig(draggable: true));
        return Colors.white;
      }
    }),
  ),
  onPressed: () { /* ... */ },
  child: Text("Button"),
)
```

### MissingPluginException

If you see `MissingPluginException(No implementation found for method window.start...)`:

1. **Clean rebuild**: `flutter clean && flutter pub get && flutter run`
2. **Check permissions**: Ensure `SYSTEM_ALERT_WINDOW` permission is granted
3. **Update to latest version**: This was fixed in recent updates

## 🤝 Contributing

Contributions are always welcome!

- Report bugs or request features via [Issues](https://github.com/jiusanzhou/flutter_floatwing/issues)
- Submit pull requests
- Improve documentation

## 📄 License

```
Apache License 2.0
Copyright (c) 2022 Zoe
```

<div align="center">

**[⬆ Back to Top](#flutter_floatwing)**

</div>
