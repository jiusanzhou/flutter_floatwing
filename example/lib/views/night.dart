

import 'package:flutter/material.dart';

class NightView extends StatefulWidget {
  const NightView({ Key? key }) : super(key: key);

  @override
  State<NightView> createState() => _NightViewState();
}

class _NightViewState extends State<NightView> {

  Color color = Color.fromARGB(255, 192, 200, 41).withOpacity(0.20);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: color,
    );
  }
}