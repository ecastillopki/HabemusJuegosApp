import 'package:flutter/material.dart';
import 'shape.dart';
import 'dart:async';

void main() {
  runApp(new MaterialApp(
    title: "chwazi",
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppstate createState() => new _MyAppstate();
}

class _MyAppstate extends State<MyApp> with WidgetsBindingObserver {
  Map<int, _Pair<Widget, bool>> map = new Map();

  int targetNum = 1;
  int _status = Status.waiting;
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Stack(
        children: <Widget>[
          Listener(
            child: Container(
              color: Colors.black,
            ),
            onPointerDown: (event) {
              if (_status == Status.waiting) {
                setState(() {
                  map.addAll({
                    event.pointer: _Pair(
                      first: Shape(
                        pointer: event.pointer,
                        x: event.position.dx,
                        y: event.position.dy,
                        onReady: _ready,
                      ),
                      last: false,
                    )
                  });
                });
              }
            },
            onPointerMove: (event) {
              setState(() {
                if (_status == Status.waiting &&
                    map.keys.contains(event.pointer)) {
                  map[event.pointer] = _Pair(
                    first: Shape(
                      pointer: event.pointer,
                      x: event.position.dx,
                      y: event.position.dy,
                      onReady: _ready,
                    ),
                    last: map[event.pointer]!.last,
                  );
                } else if (_status == Status.voting &&
                    map.keys.contains(event.pointer)) {
                  map[event.pointer] = _Pair(
                    first: Shape(
                      pointer: event.pointer,
                      x: event.position.dx,
                      y: event.position.dy,
                      onReady: _ready,
                    ),
                    last: true,
                  );
                }
              });
            },
            onPointerUp: (event) {
              setState(() {
                switch (_status) {
                  case Status.waiting:
                    _remove(event.pointer);
                    break;
                  case Status.voting:
                    _remove(event.pointer);
                    _status = Status.waiting;
                    break;
                  case Status.voted:
                    if (map.keys.contains(event.pointer)) {
                      _status = Status.waiting;
                      //TODO:调用销毁函数
                      map.remove(event.pointer);
                    }
                    break;
                  default:
                    break;
                }
              });
            },
          )
        ]..addAll(
            map.values.map((e) => e.first),
          ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => {}), // TODO: 设计选单
        tooltip: 'optional',
        child: const Icon(Icons.menu),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
    );
  }

  void _remove(int pointer) {
    map.remove(pointer);
  }

  late Timer timer;
  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    Timer.periodic(period, (timer) {
      _vote();
      this.timer = timer;
    });
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    timer.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        map.clear();
        break;
      case AppLifecycleState.inactive:
        // TODO: Handle this case.
        break;
      case AppLifecycleState.paused:
        map.clear();
        break;
      case AppLifecycleState.detached:
        // TODO: Handle this case.
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  void _ready(int pointer, bool isReady) {
    map[pointer]!.last = isReady;
  }

  final period = const Duration(microseconds: 500);
  //选出
  void _vote() {
    if (_status == Status.waiting &&
        map.length > targetNum &&
        !map.values.map((e) => e.last).contains(false)) {
      _status = Status.voting;
      // 设定计时器
      Timer(const Duration(seconds: 1), () {
        if (_status == Status.voting) {
          List<int> list = map.keys.toList()..shuffle();
          setState(() {
            for (int i = targetNum; i < list.length; i++) {
              map.remove(list[i]);
            }
          });
          _status = Status.voted;
        }
      });
      if (targetNum == 1) {
        //TODO:启动下层的Shrinking动画
      }
    }
  }
}

class Status {
  static const int waiting = 0;
  static const int voting = 1; // 正在投票中，此时可以暂时放弃投票
  static const int voted = 2;
}

class _Pair<F, L> {
  _Pair({required this.first, required this.last});
  F first;
  L last;
}
