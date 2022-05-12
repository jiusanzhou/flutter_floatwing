import 'package:flutter/material.dart';

import 'package:flutter_floatwing/flutter_floatwing.dart';
import 'package:flutter_floatwing_example/views/assistive_touch.dart';
import 'package:flutter_floatwing_example/views/night.dart';
import 'package:flutter_floatwing_example/views/normal.dart';

void main() {
  // only need this when you use main as window engine's entry point
  FloatwingPlugin().ensureWindow();

  runApp(MyApp());
}

@pragma("vm:floatwing")
void floatwing() {
  // only need this when you use main as window engine's entry point
  FloatwingPlugin().ensureWindow();

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
        "/normal": ((_) => NonrmalView()).floatwing(),
        "/night": ((_) => NightView()).floatwing(),
        "/assitive_touch": ((_) => AssistiveTouch()).floatwing(),
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
  @override
  void initState() {
    super.initState();

    initSyncState();
  }

  var _windows = [
    WindowConfig(
      id: "normal",
      // entry: "floatwing",
      route: "/normal",
      draggable: true,
      // gravity: 3 | 48,
    ).to(),
    WindowConfig(
      id: "assitive_touch",
      // entry: "floatwing",
      route: "/assitive_touch",
      draggable: true,
      // gravity: 3 | 48,
    ).to(),
    WindowConfig(
      id: "night",
      // entry: "floatwing",
      route: "/night",
      width: -1, height: -1,
      clickable: false,
    ).to()
  ];

  Map<Window, bool> _readys = {};

  initSyncState() async {
    await FloatwingPlugin().initialize();

    await FloatwingPlugin().isServiceRunning().then((v) async {
      if (!v)
        await FloatwingPlugin().startService().then((_) {
          print("start the backgroud service success.");
        });
    });

    _windows.forEach((w) => w
        .on("created", (window, data) {
          _readys[window] = true;
          setState(() {});
        })
        .create()
        .then((value) {
          _readys[w] = true;
          setState(() {});
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Floatwing example app'),
      ),
      body: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 5,
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
            ..._windows
                .map((w) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pushNamed(context, w.config!.route!);
                          },
                          child: Text("Debug ${w.config!.id}"),
                        ),
                        ElevatedButton(
                          onPressed: _readys[w] != true
                              ? null
                              : () async {
                                  w.start();
                                },
                          child: Text("Open ${w.config!.id}"),
                        ),
                      ],
                    ))
                .toList(),
            ElevatedButton(
                onPressed: () {
                  FloatwingPlugin().windows.values.forEach((w) {
                    w.close(force: false);
                  });
                },
                child: Text("Close all"))
          ],
        ),
      ),
    );
  }
}
