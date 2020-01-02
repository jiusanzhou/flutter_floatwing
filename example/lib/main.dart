import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_floatwing/flutter_floatwing.dart';
import 'package:flutter_floatwing_example/views/night.dart';
import 'package:flutter_floatwing_example/views/normal.dart';

void main() {
  runApp(MyApp());
}

@pragma("vm:floatwing")
void floatwing() {
  runApp(MaterialApp(
    home: FloatwingContainer(
      builder: ((_) => NonrmalView()).floatwing(),
    ),
  ));
}

void floatwing2(Window w) {
  runApp(MaterialApp(
    home: NonrmalView().floatwing(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    FloatwingPlugin().isServiceRunning().then((v) {
      if (!v) FloatwingPlugin().startService().then((_) {
        print("start the backgroud service success.");
      });
    });
    FloatwingPlugin().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      routes: {
        "/": (_) => HomePage(),
        "/normal": ((_) => NonrmalView().floatwing()),
        "/night": ((_) => NightView()).floatwing()
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({ Key? key }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  Window? _nornmal;
  Window? _night;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Floatwing example app'),
        ),
        body: Center(
          child: Wrap(
            direction: Axis.vertical,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton(onPressed: () async {
                    var r = await FloatwingPlugin().checkPermission();
                    if (!r) {
                      FloatwingPlugin().openPermissionSetting();
                      print("no permission, need to grant");
                    }
                  }, child: Text("Check permission")),
                ],
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                children: [
                  ElevatedButton(onPressed: () async {
                    Navigator.pushNamed(context, '/normal');
                  }, child: Text("Debug Normal")),
                  ElevatedButton(onPressed: () async {
                    Navigator.pushNamed(context, '/night');
                  }, child: Text("Debug Night")),
                ],
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                children: [
                  ElevatedButton(onPressed: () async {
                    _nornmal = await WindowConfig(
                      // entry: "floatwing",
                      route: "/normal",
                    ).start(id: "normal");
                  }, child: Text("Open Normal")),
                  ElevatedButton(onPressed: () async {
                    _night = await WindowConfig(
                      // entry: "floatwing",
                      route: "/night",
                      width: -1, height: -1,
                      clickable: false,
                    ).start(id: "night");
                  }, child: Text("Open Night")),
                ],
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                children: [
                  ElevatedButton(onPressed: () {
                    FloatwingPlugin().windows.forEach((w) {
                      w.close(hard: false);
                    });
                  }, child: Text("Close all"))
                ],
              ),
            ],
          ),
        ),
      );
  }
}
