<div align="center">

# flutter_floatwing

**Create beautiful floating overlay windows on Android with pure Flutter**

[![Pub Version](https://img.shields.io/pub/v/flutter_floatwing?color=blue&logo=dart)](https://pub.dev/packages/flutter_floatwing)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android-green.svg)](https://flutter.dev)

<br/>

<img src="./assets/flutter-floatwing-example-1.gif" width="200" alt="Night mode">
&nbsp;&nbsp;&nbsp;&nbsp;
<img src="./assets/flutter-floatwing-example-2.gif" width="200" alt="Simple example">
&nbsp;&nbsp;&nbsp;&nbsp;
<img src="./assets/flutter-floatwing-example-3.gif" width="200" alt="Assistive touch">

</div>

<br/>

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🎨 **Pure Flutter** | Write overlay windows entirely in Flutter — no native code needed |
| 🚀 **Simple API** | Start an overlay window with just 1 line of code |
| 📐 **Auto Resize** | Window automatically resizes to fit your Flutter widget |
| 🪟 **Multi-window** | Create multiple overlay windows with parent-child relationships |
| 💬 **Communication** | Share data between main app and overlay windows seamlessly |
| 📡 **Event System** | Subscribe to window lifecycle and drag events |

<br/>

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_floatwing: ^0.2.1
```

Or run:

```bash
flutter pub add flutter_floatwing
```

<br/>

## 🚀 Quick Start

### 1. Add Permission

In `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
```

### 2. Setup Routes

```dart
MaterialApp(
  routes: {
    "/": (_) => HomePage(),
    "/overlay": (_) => MyOverlayWidget(),  // Your overlay window
  },
);
```

### 3. Initialize & Request Permission

```dart
// Check and request permission
FloatwingPlugin().checkPermission().then((granted) {
  if (!granted) FloatwingPlugin().openPermissionSetting();
});

// Initialize plugin
FloatwingPlugin().initialize();
```

### 4. Launch Overlay Window

```dart
// That's it! One line to start your overlay
WindowConfig(route: "/overlay").to().create(start: true);
```

<br/>

## 📖 Usage Guide

### Window Configuration

```dart
// Basic window
WindowConfig(route: "/overlay").to().create(start: true);

// With custom ID and event handlers
WindowConfig(id: "my-window", route: "/overlay")
    .to()
    .on(EventType.WindowCreated, (window, _) => print("Created!"))
    .on(EventType.WindowDestroy, (window, _) => print("Destroyed!"))
    .create(start: true);
```

### Three Ways to Define Entry Points

| Method | Config | Use Case |
|--------|--------|----------|
| **Route** | `WindowConfig(route: "/overlay")` | Simplest — use your existing routes |
| **Callback** | `WindowConfig(callback: myMain)` | Direct function reference |
| **Entry Point** | `WindowConfig(entry: "myMain")` | String-based, requires `@pragma` |

<details>
<summary><b>Entry Point Example</b></summary>

```dart
@pragma("vm:entry-point")
void myOverlayMain() {
  runApp(MyOverlayWidget().floatwing(app: true));
}

// Then use:
WindowConfig(entry: "myOverlayMain").to().create(start: true);
```

</details>

### Access Window in Overlay

```dart
class _MyOverlayState extends State<MyOverlay> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance?.addPostFrameCallback((_) {
      final window = Window.of(context);
      print("Window ID: ${window?.id}");
    });
  }
}
```

### Share Data Between Windows

**Send data from main app:**

```dart
window.share({"message": "Hello!"}).then((response) {
  print("Window responded: $response");
});
```

**Receive data in overlay:**

```dart
window?.onData((source, name, data) async {
  print("Received from $source: $data");
  return "Got it!";  // Optional response
});
```

### Subscribe to Events

```dart
window?.on(EventType.WindowStarted, (w, _) {
  print("Window started");
}).on(EventType.WindowDragEnd, (w, position) {
  print("Dragged to: $position");
});
```

**Available Events:**

| Lifecycle | Actions |
|-----------|---------|
| `WindowCreated` | `WindowDragStart` |
| `WindowStarted` | `WindowDragging` |
| `WindowPaused` | `WindowDragEnd` |
| `WindowResumed` | |
| `WindowDestroy` | |

<br/>

## 🏗️ Architecture

<details>
<summary><b>How it works</b></summary>

<br/>

Each floating window consists of:
- A **Flutter Engine** running your widget via `runApp`
- An **Android View** attached to the Window Manager

<img src="./assets/flutter-floatwing-window.png" width="400" alt="Window structure">

<br/>

**Key Concepts:**

- **Main Engine**: The Flutter engine from your main app
- **Window Engine**: Separate engines for each overlay window
- Engines run in **different threads** and communicate via `share()`
- **Window ID** is required and unique for each window

<br/>

<img src="./assets/flutter-floatwing-arch.png" width="600" alt="Architecture">

</details>

<br/>

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

Create nested windows from within an overlay:

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

<br/>

## 🤝 Contributing

Contributions are welcome! Feel free to:

- Report bugs or request features via [Issues](https://github.com/jiusanzhou/flutter_floatwing/issues)
- Submit pull requests
- Improve documentation

<br/>

## 📄 License

```
Apache License 2.0
Copyright (c) 2022 Zoe
```

<br/>

<div align="center">

**[⬆ Back to Top](#flutter_floatwing)**

</div>
