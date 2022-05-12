import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

@immutable
class AssistiveTouch extends StatefulWidget {
  const AssistiveTouch({
    Key? key,
    this.child = const _DefaultChild(),
    this.visible = true,
    this.draggable = false,
    this.shouldStickToSide = true,
    this.margin = const EdgeInsets.all(8.0),
    this.initialOffset = Offset.infinite,
    this.onTap,
    this.animatedBuilder,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// Switches between showing the [child] or hiding it.
  final bool visible;

  /// Whether it can be dragged.
  final bool draggable;

  /// Whether it sticks to the side.
  final bool shouldStickToSide;

  /// Empty space to surround the [child].
  final EdgeInsets margin;

  /// Initial position.
  ///
  /// For example, if you want to put Assistive Touch to left-bottom cornor:
  ///
  /// ```dart
  /// AssistiveTouch(
  ///   initialOffset: const Offset(double.infinity, 0);
  ///   ...
  /// )
  /// ```
  final Offset initialOffset;

  /// A tap with a primary button has occurred.
  final VoidCallback? onTap;

  /// Custom animated builder.
  final Widget Function(
    BuildContext context,
    Widget child,
    bool visible,
  )? animatedBuilder;

  @override
  _AssistiveTouchState createState() => _AssistiveTouchState();
}

class _AssistiveTouchState extends State<AssistiveTouch>
    with TickerProviderStateMixin {
  bool isInitialized = false;
  late Offset offset = widget.initialOffset;
  late Offset largerOffset = offset;
  Size size = Size.zero;
  bool isDragging = false;
  bool isIdle = true;
  Timer? timer;
  late final AnimationController _scaleAnimationController =
      AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  )..addListener(() {
          setState(() {});
        });
  late final Animation<double> _scaleAnimation = CurvedAnimation(
    parent: _scaleAnimationController,
    curve: Curves.easeInOut,
  );
  Timer? scaleTimer;

  Window? window;

  @override
  void initState() {
    super.initState();
    scaleTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (mounted == false) {
        return;
      }

      if (widget.visible) {
        _scaleAnimationController.forward();
      } else {
        _scaleAnimationController.reverse();
      }
    });
    FocusManager.instance.addListener(listener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isInitialized == false) {
      isInitialized = true;
      _setOffset(offset);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    scaleTimer?.cancel();
    _scaleAnimationController.dispose();
    FocusManager.instance.removeListener(listener);
    super.dispose();
  }

  void listener() {
    Timer(const Duration(milliseconds: 200), () {
      if (mounted == false) return;
      largerOffset = Offset(
        max(largerOffset.dx, offset.dx),
        max(largerOffset.dy, offset.dy),
      );

      _setOffset(largerOffset, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    var child = widget.child;

    child = _MyMeasuredSize(
      child: child,
      onChange: (size) {
        setState(() {
          this.size = size;
        });
        _setOffset(offset);
      },
    );

    if (window == null) {
      window = Window.of(context);
      window?.on("drag_start", (window, data) => _onDragStart());
      window?.on("dragging", (window, data) {
        var p = data as List<dynamic>;
        _onDragUpdate(p[0], p[1]);
      });
      window?.on("drag_end", (window, data) => _onDragEnd());
    }

    child = GestureDetector(
      onTap: _onTap,
      child: child,
    );

    child = widget.animatedBuilder != null
        ? widget.animatedBuilder!(context, child, widget.visible)
        : ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedOpacity(
              opacity: isIdle ? .3 : 1,
              duration: const Duration(milliseconds: 300),
              child: child,
            ),
          );

    return child;
  }

  void _onTap() {
    if (widget.onTap != null) {
      widget.onTap!();
      setState(() {
        isIdle = false;
      });
      _scheduleIdle();
    }
  }

  void _onDragStart() {
    setState(() {
      isDragging = true;
      isIdle = false;
    });
    timer?.cancel();
  }

  void _onDragUpdate(int x, int y) {
    _setOffset(Offset(x.toDouble(), y.toDouble()));
  }

  void _onDragEnd() {
    setState(() {
      isDragging = false;
    });
    _scheduleIdle();

    _setOffset(offset);
  }

  void _scheduleIdle() {
    timer?.cancel();
    timer = Timer(const Duration(seconds: 2), () {
      if (isDragging == false) {
        setState(() {
          isIdle = true;
        });
      }
    });
  }

  void _updatePosition() {
    window?.update(WindowConfig(
      x: offset.dx.toInt(),
      y: offset.dy.toInt(),
    ));
  }

  void _setOffset(Offset offset, [bool shouldUpdateLargerOffset = true]) {
    if (shouldUpdateLargerOffset) {
      largerOffset = offset;
    }

    if (isDragging) {
      setState(() {
        this.offset = offset;
      });

      return;
    }

    final screenSize =
        window?.system?.screenSize ?? MediaQuery.of(context).size;
    final screenPadding = MediaQuery.of(context).padding;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final left = screenPadding.left + viewInsets.left + widget.margin.left;
    final top = screenPadding.top + viewInsets.top + widget.margin.top;
    final right = screenSize.width -
        screenPadding.right -
        viewInsets.right -
        widget.margin.right -
        size.width;
    final bottom = screenSize.height -
        screenPadding.bottom -
        viewInsets.bottom -
        widget.margin.bottom -
        size.height;

    final halfWidth = (right - left) / 2;

    if (widget.shouldStickToSide) {
      final normalizedTop = max(min(offset.dy, bottom), top);
      final normalizedLeft = max(
        min(
          normalizedTop == bottom || normalizedTop == top
              ? offset.dx
              : offset.dx < halfWidth
                  ? left
                  : right,
          right,
        ),
        left,
      );
      this.offset = Offset(normalizedLeft, normalizedTop);
    } else {
      final normalizedTop = max(min(offset.dy, bottom), top);
      final normalizedLeft = max(min(offset.dx, right), left);
      this.offset = Offset(normalizedLeft, normalizedTop);
    }
    _updatePosition();
  }
}

class _MyMeasuredSize extends StatefulWidget {
  const _MyMeasuredSize({
    Key? key,
    required this.onChange,
    required this.child,
  }) : super(key: key);

  final Widget child;

  final void Function(Size size) onChange;

  @override
  _MyMeasuredSizeState createState() => _MyMeasuredSizeState();
}

class _MyMeasuredSizeState extends State<_MyMeasuredSize> {
  @override
  void initState() {
    SchedulerBinding.instance!.addPostFrameCallback(postFrameCallback);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance!.addPostFrameCallback(postFrameCallback);
    return Container(
      key: widgetKey,
      child: widget.child,
    );
  }

  final widgetKey = GlobalKey();
  Size? oldSize;

  void postFrameCallback(Duration _) async {
    final context = widgetKey.currentContext!;

    await Future<void>.delayed(
      const Duration(milliseconds: 100),
    );
    if (mounted == false) return;

    final newSize = context.size!;
    if (newSize == Size.zero) return;
    if (oldSize == newSize) return;
    oldSize = newSize;
    widget.onChange(newSize);
  }
}

class _DefaultChild extends StatelessWidget {
  const _DefaultChild({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.all(Radius.circular(28)),
      ),
      child: Container(
        height: 40,
        width: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[400]!.withOpacity(.6),
          borderRadius: const BorderRadius.all(Radius.circular(28)),
        ),
        child: Container(
          height: 32,
          width: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey[300]!.withOpacity(.6),
            borderRadius: const BorderRadius.all(Radius.circular(28)),
          ),
          child: Container(
            height: 24,
            width: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
