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

  static T? of<T>(BuildContext context) {
    return null;
  }
}

class FloatwingContainer extends StatefulWidget {
  final Widget? child;
  final WidgetBuilder? builder;

  const FloatwingContainer({
    Key? key,
    this.child,
    this.builder,
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
      log("[provider] don't sync window at init, need to do at here");
      await FloatwingPlugin().ensureWindow().then((w) => _window = w);
    }
    // init window from engine and save, only call this int here
    // sync a window from engine
    _updateFromWindow();
    _window?.on(EventType.WindowResumed, (w, _) => _updateFromWindow());
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: _MeasuredSized(
        onChange: _autosize ? _onSizeChanged : null,
        child: FloatwingProvider(
          child: Builder(builder: widget.builder ?? (_) => widget.child!),
          window: _window,
        ).ignorePointer(ignoring: _ignorePointer),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    // TODO: remove event listener
    // w.un("resumed").un("")
  }


  _updateFromWindow() {
    // clickable == !ignorePointer
    _ignorePointer = !(_window?.config?.clickable ?? true);
    _autosize = _window?.config?.autosize ?? true;

    log("[provider] the view to ignore pointer: $_ignorePointer");

    // update the flutter ui
    setState(() {});
  }

  _onSizeChanged(Size size) {
    var radio = _window?.pixelRadio ?? 0;
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

extension _IgnorePointerExtension on Widget {
  Widget ignorePointer({bool ignoring = false}) {
    return IgnorePointer(child: this, ignoring: ignoring);
  }
}

extension WidgetProviderExtension on Widget {
  Widget floatwing({
    bool ignorePointer = false,
  }) {
    return FloatwingContainer(
      child: this,
    );
  }
}

extension WidgetBuilderProviderExtension on WidgetBuilder {
  WidgetBuilder floatwing({
    bool ignorePointer = false,
  }) {
    return (_) => FloatwingContainer(
          builder: this,
        );
  }

  Widget make() {
    return Builder(builder: this);
  }
}
