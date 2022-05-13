import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

class NonrmalView extends StatefulWidget {
  const NonrmalView({ Key? key }) : super(key: key);

  @override
  State<NonrmalView> createState() => _NonrmalViewState();
}

class _NonrmalViewState extends State<NonrmalView> {

  bool _expend = false;
  double _size = 100;

  @override
  void initState() {
    super.initState();
  }

  Window? w;
  bool dragging = false;

  @override
  Widget build(BuildContext context) {
    // context.floatwingWindow
    if (w == null) {
      w = Window.of(context);
      w?.on(EventType.WindowDragStart, (window, data) {
        if(mounted) setState(() => { dragging = true });
      });
      w?.on(EventType.WindowDragEnd, (window, data) {
        if(mounted) setState(() => { dragging = false });
      });
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 50),
      width: _size,
      height: _size,
      child: Card(
        color: dragging ? Colors.green : null,
        child: Center(
          child: Wrap(
            direction: Axis.vertical,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton(onPressed: () {
                print("window in custom view: $w");
                _expend = !_expend;
                setState(() {
                  _size = _expend ? 200 : 100;
                });
              }, child: Icon(_expend?Icons.expand_more:Icons.expand_less)),
            ],
          )
        ),
      )
    );
  }
}