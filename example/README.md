# flutter_floatwing Example

This example demonstrates the core features of `flutter_floatwing` plugin.

## Demos Included

| Demo | Description |
|------|-------------|
| **Normal** | Basic draggable floating window |
| **Assistive Touch** | iOS-style assistive touch button |
| **Night Mode** | Full-screen non-clickable overlay filter |

## Running the Example

### Prerequisites

- Flutter SDK (>=1.20.0)
- Android device or emulator (API 21+)
- USB debugging enabled

### Steps

```bash
# Clone the repository
git clone https://github.com/jiusanzhou/flutter_floatwing.git
cd flutter_floatwing/example

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### Grant Permission

When you first run the app, you'll need to grant the **"Display over other apps"** permission:

1. Click "Start" button in the app
2. System will redirect to permission settings
3. Enable the permission for the example app
4. Return to the app

## Project Structure

```
example/
├── lib/
│   ├── main.dart              # App entry & home page
│   └── views/
│       ├── normal.dart        # Basic floating window
│       ├── assistive_touch.dart  # Assistive touch demo
│       └── night.dart         # Night mode overlay
└── android/
    └── app/src/main/
        └── AndroidManifest.xml  # Permission declaration
```

## Key Code Examples

### Creating Multiple Windows

```dart
var _configs = [
  WindowConfig(id: "normal", route: "/normal", draggable: true),
  WindowConfig(id: "assistive", route: "/assistive", draggable: true),
  WindowConfig(
    id: "night",
    route: "/night",
    width: WindowSize.MatchParent,
    height: WindowSize.MatchParent,
    clickable: false,  // Touch passes through
  ),
];
```

### Using Route-based Entry Points

```dart
// Register routes with .floatwing() wrapper
Map<String, Widget Function(BuildContext)> _routes = {
  "/": (_) => HomePage(),
  "/normal": (_) => NormalView().floatwing(),
  "/assistive": (_) => AssistiveTouch().floatwing(),
  "/night": (_) => NightView().floatwing(),
};
```

## Troubleshooting

**Window not appearing?**
- Ensure permission is granted
- Check if service is running: `FloatwingPlugin().isServiceRunning()`

**MissingPluginException?**
- Clean rebuild: `flutter clean && flutter pub get && flutter run`

**Debug mode issues?**
- Use route-based entry points for easier debugging
- Navigate to the route directly to test your overlay widget
