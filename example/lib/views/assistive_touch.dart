import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

class AssistiveTouch extends StatefulWidget {
  const AssistiveTouch({Key? key}) : super(key: key);

  @override
  State<AssistiveTouch> createState() => _AssistiveTouchState();
}

void _pannelMain() {
  runApp(((_) => AssistivePannel()).floatwing(app: true).make());
}

class _AssistiveTouchState extends State<AssistiveTouch> {
  /// The state of the touch state
  bool expend = false;
  bool pannelReady = false;
  Window? pannelWindow;
  Window? touchWindow;

  @override
  void initState() {
    super.initState();

    initAsyncState();

    SchedulerBinding.instance?.addPostFrameCallback((_) {
      touchWindow = Window.of(context);
      touchWindow?.on(EventType.WindowStarted, (window, data) {
        print("touch window start ...");
        expend = false;
        setState(() {});
      });
    });
  }

  void initAsyncState() async {
    // create the pannel window
    pannelWindow = WindowConfig(
      id: "assistive_pannel",
      callback: _pannelMain,
      width: WindowSize.MatchParent,
      height: WindowSize.MatchParent,
      autosize: false,
    ).to();

    pannelWindow?.create();
    // we can't subscribe the events from other windows
    // that means pannelWindow's events can't be fired to here.
    // This is a feature, make sure window only care about events
    // from self. If we want to communicate with the other windows,
    // we can use the data communicatting method.
    pannelWindow?.on(EventType.WindowCreated, (window, data) {
      pannelReady = true;
      setState(() {});
    }).on(EventType.WindowPaused, (window, data) {
      // open the assitive_touch
      touchWindow?.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AssistiveButton(onTap: _onTap);
  }

  void _onTap() {
    var w = Window.of(context);
    // send the postion to pannel window
    var x = w?.config?.x ?? 0 / (w?.pixelRadio ?? 1);
    var y = w?.config?.y ?? 0 / (w?.pixelRadio ?? 1);
    pannelWindow?.share([x, y]);
    // send touchWindow postion to pannel window
    pannelWindow?.start();
    setState(() {
      // hide button
      expend = true;
    });
  }
}

@immutable
class AssistiveButton extends StatefulWidget {
  const AssistiveButton({
    Key? key,
    this.child = const _DefaultChild(),
    this.visible = true,
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

  /// Whether it sticks to the side.
  final bool shouldStickToSide;

  /// Empty space to surround the [child].
  final EdgeInsets margin;

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
  _AssistiveButtonState createState() => _AssistiveButtonState();
}

class _AssistiveButtonState extends State<AssistiveButton>
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

    if (window == null) {
      window = Window.of(context);
      window?.on(EventType.WindowDragStart, (window, data) => _onDragStart());
      window?.on(EventType.WindowDragging, (window, data) {
        var p = data as List<dynamic>;
        _onDragUpdate(p[0], p[1]);
      });
      window?.on(EventType.WindowDragEnd, (window, windowdata) => _onDragEnd());
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

  void _onTap() async {
    if (widget.onTap != null) {
      setState(() {
        isIdle = false;
      });
      _scheduleIdle();
      widget.onTap!();
    }
  }

  void _onDragStart() {
    setState(() {
      isDragging = true;
      isIdle = false;
    });
    timer?.cancel();
  }

  Offset _old = Offset.zero;
  void _onDragUpdate(int x, int y) {
    _old = Offset(x.toDouble(), y.toDouble());
    _setOffset(_old);
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

  /// TODO: this function should depend on the gravity to calcute the position
  void _setOffset(Offset offset, [bool shouldUpdateLargerOffset = true]) {
    if (shouldUpdateLargerOffset) {
      largerOffset = offset;
    }

    if (isDragging) {
      this.offset = offset;
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

  // Offset _applyGravity(Offset o) {
  //   return window?.config?.gravity.apply(o) ?? o;
  // }
}

class AssistivePannel extends StatefulWidget {
  const AssistivePannel({
    Key? key,
  }) : super(key: key);

  @override
  State<AssistivePannel> createState() => _AssistivePannelState();
}

class _AssistivePannelState extends State<AssistivePannel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController = AnimationController(
    duration: _duration,
    vsync: this,
  );

  Duration _duration = Duration(milliseconds: 200);

  Window? window;

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) {
      window = Window.of(context);
      window?.on(EventType.WindowStarted, (window, data) {
        // if start just show
        print("pannel just start ...");
        setState(() {
          _show = true;
        });
      }).onData((source, name, data) async {
        int x = data[0];
        int y = data[1];
        _updatePostion(x, y);
        return;
      });
    });
  }

  double? _left;
  double? _right;
  double? _top;
  bool _isLeft = false;
  _updatePostion(int x, int y) {
    _isLeft = x < 50;
    if (y <= size) {
      _top = fixed;
    } else if (y >= screenHeight - size) {
      _top = screenHeight - size - fixed;
    } else {
      _top = y - size / 2;
    }
  }

  var fixed = 100.0;
  var factor = 0.8;

  double screenWidth = 0.0;
  double screenHeight = 0.0;
  double size = 0.0;

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    size = screenWidth * factor;

    return GestureDetector(
      onTap: _onTap,
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Container(color: Colors.red),
            AnimatedPositioned(
                bottom: _bottom,
                height: _show ? size : 0,
                left: _show ? 0 : screenWidth / 2,
                right: _show ? 0 : screenWidth / 2,
                curve: Curves.easeIn,
                duration: _duration,
                child: FractionallySizedBox(
                  widthFactor: factor,
                  child: GestureDetector(
                      onTap: () => null,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          color: Color.fromARGB(255, 25, 24, 24),
                        ),
                        child: Stack(
                          children: [],
                        ),
                      )),
                )),
          ],
        ),
      ),
    );
  }

  bool _show = false;

  double? _bottom = 200;

  _onTap() {
    setState(() {
      _show = false;
    });
    Timer(_duration, () => window?.close());
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
