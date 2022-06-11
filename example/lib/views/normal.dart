import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

class NonrmalView extends StatefulWidget {
  const NonrmalView({Key? key}) : super(key: key);

  @override
  State<NonrmalView> createState() => _NonrmalViewState();
}

class _NonrmalViewState extends State<NonrmalView> {
  bool _expend = false;
  double _size = 150;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) {
      w = Window.of(context);
      w?.on(EventType.WindowDragStart, (window, data) {
        if (mounted) setState(() => {dragging = true});
      }).on(EventType.WindowDragEnd, (window, data) {
        if (mounted) setState(() => {dragging = false});
      });
    });
  }

  Window? w;
  bool dragging = false;

  _changeSize() {
    _expend = !_expend;
    _size = _expend ? 250 : 150;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: _size,
        height: _size,
        color: dragging ? Colors.yellowAccent : null,
        child: Card(
            child: Stack(
          children: [
            Center(
                child: ElevatedButton(
                    onPressed: () {
                      w?.launchMainActivity();
                    },
                    child: Text("Start Activity"))),
            Positioned(
                right: 5, top: 5, child: Icon(Icons.drag_handle_rounded)),
            Positioned(
                right: 5,
                bottom: 5,
                child: RotationTransition(
                    turns: AlwaysStoppedAnimation(-45 / 360),
                    child: InkWell(
                        onTap: _changeSize,
                        child: Icon(Icons.unfold_more_rounded))))
          ],
        )),
      ),
    );
  }
}
