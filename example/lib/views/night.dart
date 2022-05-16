import 'package:flutter/material.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

class NightView extends StatefulWidget {
  const NightView({Key? key}) : super(key: key);

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

  var _show = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _show ? MediaQuery.of(context).size.height : 0,
      width: _show ? MediaQuery.of(context).size.width : 0,
      color: color,
    );
  }
}
