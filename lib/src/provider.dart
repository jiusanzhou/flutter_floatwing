import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

// typedef TransitionBuilder = Widget Function(BuildContext context, Widget? child);
// typedef WidgetBuilder = Widget Function(BuildContext context);

class FloatwingProvider extends InheritedWidget {
  final Window? window;
  final Widget child;

  FloatwingProvider({
    Key? key,
    required this.child,
    required this.window,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(FloatwingProvider oldWidget) {
    return true;
  }
}

class FloatwingContainer extends StatefulWidget {
  final Widget? child;
  final WidgetBuilder? builder;
  final bool debug;

  const FloatwingContainer({
    Key? key,
    this.child,
    this.builder,
    this.debug = false,
  })  : assert(child != null || builder != null),
        super(key: key);

  @override
  State<FloatwingContainer> createState() => _FloatwingContainerState();
}

class _FloatwingContainerState extends State<FloatwingContainer> {
  Window? _window = FloatwingPlugin().currentWindow;

  var _ignorePointer = false;
  var _autosize = true;

  @override
  void initState() {
    super.initState();
    initSyncState();
  }

  initSyncState() async {
    if (_window == null) {
      log("[provider] have not sync window at init, need to do at here");
      await FloatwingPlugin().ensureWindow().then((w) => _window = w);
    }
    // init window from engine and save, only call this int here
    // sync a window from engine
    _changed();
    _window?.on(EventType.WindowResumed, (w, _) => _changed());
  }

  Widget _empty = Container();

  @override
  Widget build(BuildContext context) {
    // make sure window is ready?
    if (!widget.debug && _window == null) return _empty;
    // in production, make sure builder when window is ready
    return Builder(builder: widget.builder ?? (_) => widget.child!)
        ._provider(_window)
        ._autosize(enabled: _autosize, onChange: _onSizeChanged)
        ._material(color: Colors.transparent)
        ._pointerless(_ignorePointer);
  }

  @override
  void dispose() {
    super.dispose();
    // TODO: remove event listener
    // w.un("resumed").un("")
  }

  _changed() async {
    // clickable == !ignorePointer
    _ignorePointer = !(_window?.config?.clickable ?? true);
    _autosize = _window?.config?.autosize ?? true;
    // update the flutter ui
    if (mounted) setState(() {});
  }

  _onSizeChanged(Size size) {
    var radio = _window?.pixelRadio ?? 1;
    _window?.update(WindowConfig(
      width: (size.width * radio).toInt(),
      height: (size.height * radio).toInt(),
    ));
  }
}

class _MeasuredSized extends StatefulWidget {
  const _MeasuredSized({
    Key? key,
    required this.onChange,
    required this.child,
    this.delay = 0,
  }) : super(key: key);

  final Widget child;

  final int delay;

  final void Function(Size size)? onChange;

  @override
  _MeasuredSizedState createState() => _MeasuredSizedState();
}

class _MeasuredSizedState extends State<_MeasuredSized> {
  @override
  void initState() {
    SchedulerBinding.instance!.addPostFrameCallback(postFrameCallback);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onChange == null) return widget.child;
    SchedulerBinding.instance!.addPostFrameCallback(postFrameCallback);
    return UnconstrainedBox(
      child: Container(
        key: widgetKey,
        child: NotificationListener<SizeChangedLayoutNotification>(
          onNotification: (_) {
            SchedulerBinding.instance?.addPostFrameCallback(postFrameCallback);
            return true;
          },
          child: SizeChangedLayoutNotifier(child: widget.child),
        ),
      ),
    );
  }

  final widgetKey = GlobalKey();
  Size? oldSize;

  void postFrameCallback(Duration _) async {
    final context = widgetKey.currentContext!;

    if (widget.delay > 0)
      await Future<void>.delayed(Duration(milliseconds: widget.delay));
    if (mounted == false) return;

    final newSize = context.size!;
    if (newSize == Size.zero) return;
    // if (oldSize == newSize) return;
    oldSize = newSize;
    widget.onChange!(newSize);
  }
}

extension WidgetProviderExtension on Widget {
  /// Export floatwing extension function to inject for widget
  Widget floatwing({ bool debug = false }) {
    return FloatwingContainer(child: this, debug: debug);
  }

  Widget _provider(Window? window) {
    return FloatwingProvider(child: this, window: window);
  }

  Widget _pointerless([bool ignoring = false]) {
    return IgnorePointer(child: this, ignoring: ignoring);
  }

  Widget _material({
    bool enabled = false,
    Color? color,
  }) {
    return !enabled ? this : Material(color: color, child: this);
  }

  Widget _autosize({
    bool enabled = false,
    void Function(Size)? onChange,
    int delay = 0,
  }) {
    return !enabled
        ? this
        : _MeasuredSized(child: this, delay: delay, onChange: onChange);
  }
}

extension WidgetBuilderProviderExtension on WidgetBuilder {
  WidgetBuilder floatwing({ bool debug = false }) {
    return (_) => FloatwingContainer(builder: this, debug: debug);
  }

  Widget make() {
    return Builder(builder: this);
  }
}
