import 'package:flutter/material.dart';

import 'package:flutter_floatwing/flutter_floatwing.dart';
import 'package:flutter_floatwing_example/views/assistive_touch.dart';
import 'package:flutter_floatwing_example/views/night.dart';
import 'package:flutter_floatwing_example/views/normal.dart';

void main() {
  runApp(MyApp());
}

@pragma("vm:entry-point")
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
  var _configs = [
    WindowConfig(
      id: "normal",
      // entry: "floatwing",
      route: "/normal",
      draggable: true,
      // gravity: 3 | 48,
    ),
    WindowConfig(
      id: "assitive_touch",
      // entry: "floatwing",
      route: "/assitive_touch",
      draggable: true,
      // gravity: 3 | 48,
    ),
    WindowConfig(
      id: "night",
      // entry: "floatwing",
      route: "/night",
      width: -1, height: -1,
      clickable: false,
    )
  ];

  Map<String, WidgetBuilder> _builders = {
    "normal": (_) => NonrmalView(),
    "assitive_touch": (_) => AssistiveTouch(),
    "night": (_) => NightView(),
  };

  Map<String, Widget Function(BuildContext)> _routes = {};

  @override
  void initState() {
    super.initState();

    _routes["/"] = (_) => HomePage(configs: _configs);

    _configs.forEach((c) => {
          if (c.route != null && _builders[c.id] != null)
            {_routes[c.route!] = _builders[c.id]!.floatwing()}
        });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      routes: _routes,
    );
  }
}

class HomePage extends StatefulWidget {
  final List<WindowConfig> configs;
  const HomePage({Key? key, required this.configs}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    widget.configs.forEach((c) => _windows.add(c.to()));

    initSyncState();
  }

  List<Window> _windows = [];

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
        .on(EventWindowCreated, (window, data) {
          _readys[window] = true;
          setState(() {});
        })
        .create()
        .then((_) {
          if (_!=null) {
            _readys[w] = true;
            setState(() {});
          }
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
                          child: Text("Debug ${w.id}"),
                        ),
                        ElevatedButton(
                          onPressed: _readys[w] != true
                              ? null
                              : () async {
                                  w.start();
                                },
                          child: Text("Open ${w.id}"),
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
