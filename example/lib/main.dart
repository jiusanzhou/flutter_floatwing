import 'dart:convert';
import 'dart:ui';

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
  runApp(((_) => NonrmalView()).floatwing().make());
}

void floatwing2(Window w) {
  runApp(MaterialApp(
    // floatwing on widget can't use Window.of(context)
    // to access window instance
    // should use FloatwingPlugin().currentWindow
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
    ),
    WindowConfig(
      id: "assitive_touch",
      // entry: "floatwing",
      route: "/assitive_touch",
      draggable: true,
    ),
    WindowConfig(
      id: "night",
      // entry: "floatwing",
      route: "/night",
      width: WindowSize.MatchParent, height: WindowSize.MatchParent,
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
            {_routes[c.route!] = _builders[c.id]!.floatwing(debug: true)}
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

    _windows.forEach((w) {
      var _w = FloatwingPlugin().windows[w.id];
      if (null != _w) {
        // replace w with _w
        _readys[w] = true;
        return;
      }
      w.on(EventType.WindowCreated, (window, data) {
          _readys[window] = true;
          setState(() {});
        })
        .create();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Floatwing example app'),
      ),
      body: ListView(
        children: _windows.map((e) => _item(e)).toList(),
      ),
    );
  }

  _debug(Window w) {
    Navigator.of(context).pushNamed(w.config!.route!);
  }

  Widget _item(Window w) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Text(w.id, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 214, 213, 213),
                borderRadius: BorderRadius.all(Radius.circular(4))
              ),
              child: Text(w.config?.toString()??""),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: (_readys[w] == true) ? () => w.start() : null,
                  child: Text("Open"),
                ),
                TextButton(
                  onPressed: w.config?.route != null ? () => _debug(w) : null,
                  child: Text("Debug")),
                TextButton(
                  onPressed: (_readys[w] == true) ? () => w.close() : null,
                  child: Text("Close", style: TextStyle(color: Colors.red)),
                ),
              ],
            )
          ],
        )
      ),
    );
  }
}
