

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

class NightView extends StatefulWidget {
  const NightView({ Key? key }) : super(key: key);

  @override
  State<NightView> createState() => _NightViewState();
}

class _NightViewState extends State<NightView> {

  Color color = Color.fromARGB(255, 192, 200, 41).withOpacity(0.20);

  @override
  void initState() {
    super.initState();
  }

  Window? w;

  var _show = false;
  var _duration = Duration(milliseconds: 200);

  _ensure() {
    if (w != null) return;
    w = Window.of(context);
    w?.on(EventType.WindowStarted, (window, data) {
      _show = true;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    _ensure();
    return AnimatedContainer(
      duration: _duration,
      height: _show?MediaQuery.of(context).size.height:0,
      width: _show?MediaQuery.of(context).size.width:0,
      color: color,
    );
  }
}