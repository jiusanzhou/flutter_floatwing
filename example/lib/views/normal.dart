import 'dart:async';

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
  double _cSize = 100;

  @override
  void initState() {
    super.initState();
  }

  Window? w;

  @override
  Widget build(BuildContext context) {
    // context.floatwingWindow
    if (w == null) {
      w = Window.of(context);
      print("take window from context: ${w?.id}");
    }
    return Container(
      width: _cSize,
      height: _cSize,
      child: UnconstrainedBox(child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        width: _size,
        height: _size,
        child: Card(
          child: Center(
            child: Wrap(
              direction: Axis.vertical,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton(onPressed: () {
                  print("window in custom view: $w");
                  _expend = !_expend;
                  if (_expend) {
                    // increase
                    setState(() {
                      _cSize = 200;
                        _size = 200;
                    });
                    // late for child
                    Timer(Duration(milliseconds: 500), () {
                      setState(() {
                        _size = 200;
                      });
                    });
                  } else {
                    // decrease
                    setState(() {
                      _size = 100;
                        _cSize = 100;
                    });
                    // late for parernt
                    Timer(Duration(milliseconds: 500), () {
                      setState(() {
                        _cSize = 100;
                      });
                    });
                  }
                }, child: Icon(_expend?Icons.expand_more:Icons.expand_less)),
              ],
            )
          ),
        )
      )
    ));
  }
}