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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      // TODO: bug start other engine will also execute home page
      routes: {
        "/": (_) => HomePage(),
        "/normal": ((_) => NonrmalView().floatwing()),
        "/night": ((_) => NightView()).floatwing()
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Window? _nornmal;
  Window? _night;

  @override
  void initState() {
    super.initState();

    initSyncState();
  }

  initSyncState() async {
    await FloatwingPlugin().isServiceRunning().then((v) async {
      if (!v)
        await FloatwingPlugin().startService().then((_) {
          print("start the backgroud service success.");
        });
    });
    await FloatwingPlugin().initialize();
    
    _nornmal = await WindowConfig(
      id: "normal",

      // entry: "floatwing",
      route: "/normal",
      // gravity: 3 | 48,
    ).to().on("created", (w, _) {
      print("[on-normal-created] $w");
      // w.start();
    }).create(start: true);

    _night = await WindowConfig(
      id: "night",

      // entry: "floatwing",
      route: "/night",
      width: -1, height: -1,
      clickable: false,
    ).to().on("created", (w, _) {
      print("[on-night-created] $w");
      // w.start();
    }).create();
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
                ElevatedButton(
                    onPressed: () async {
                      var r = await FloatwingPlugin().checkPermission();
                      if (!r) {
                        FloatwingPlugin().openPermissionSetting();
                        print("no permission, need to grant");
                      }
                    },
                    child: Text("Check permission")),
              ],
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: [
                ElevatedButton(
                    onPressed: () async {
                      Navigator.pushNamed(context, '/normal');
                    },
                    child: Text("Debug Normal")),
                ElevatedButton(
                    onPressed: () async {
                      Navigator.pushNamed(context, '/night');
                    },
                    child: Text("Debug Night")),
              ],
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: [
                ElevatedButton(
                    onPressed: () async {
                      print("===> $_nornmal");
                      // destroy
                      _nornmal?.start();
                    },
                    child: Text("Open Normal")),
                ElevatedButton(
                    onPressed: () async {
                      _night?.start();
                    },
                    child: Text("Open Night")),
              ],
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: [
                ElevatedButton(
                    onPressed: () {
                      FloatwingPlugin().windows.values.forEach((w) {
                        w.close(force: false);
                      });
                    },
                    child: Text("Close all"))
              ],
            ),
          ],
        ),
      ),
    );
  }
}
