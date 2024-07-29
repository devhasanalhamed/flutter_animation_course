import 'dart:math' show pi;
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:flutter/material.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Application',
      theme: ThemeData(brightness: Brightness.dark),
      darkTheme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  static const double widthAndHeight = 100;
  late AnimationController _xController;
  late AnimationController _yController;
  late AnimationController _zController;
  late Tween<double> _animation;

  @override
  void initState() {
    _xController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 20,
      ),
    );

    _yController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 30,
      ),
    );

    _zController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 40,
      ),
    );

    _animation = Tween(
      begin: 0.0,
      end: pi * 2,
    );

    super.initState();
  }

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    _zController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _xController
      ..reset()
      ..repeat();

    _yController
      ..reset()
      ..repeat();

    _zController
      ..reset()
      ..repeat();

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(
              height: 150,
              width: double.infinity,
            ),
            AnimatedBuilder(
              animation: Listenable.merge(
                [
                  _xController,
                  _yController,
                  _zController,
                ],
              ),
              builder: (context, child) => Transform(
                transform: Matrix4.identity()
                  ..rotateX(_animation.evaluate(_xController))
                  ..rotateY(_animation.evaluate(_yController))
                  ..rotateZ(_animation.evaluate(_zController)),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // back
                    Container(
                      width: widthAndHeight,
                      height: widthAndHeight,
                      color: Colors.amber,
                      transform: Matrix4.identity()
                        ..translate(
                          Vector3(0, 0, -widthAndHeight),
                        ),
                    ),
                    // left side
                    Transform(
                      transform: Matrix4.identity()
                        ..rotateY(
                          (pi / 2),
                        ),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: widthAndHeight,
                        height: widthAndHeight,
                        color: Colors.purple,
                      ),
                    ),
                    // right side
                    Transform(
                      transform: Matrix4.identity()
                        ..rotateY(
                          -(pi / 2),
                        ),
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: widthAndHeight,
                        height: widthAndHeight,
                        color: Colors.green,
                      ),
                    ),
                    // front
                    Container(
                      width: widthAndHeight,
                      height: widthAndHeight,
                      color: Colors.red,
                    ),
                    // top side
                    Transform(
                      transform: Matrix4.identity()
                        ..rotateX(
                          -(pi / 2),
                        ),
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: widthAndHeight,
                        height: widthAndHeight,
                        color: Colors.teal,
                      ),
                    ),
                    // bottom side
                    Transform(
                      transform: Matrix4.identity()
                        ..rotateX(
                          -(pi / 2),
                        ),
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: widthAndHeight,
                        height: widthAndHeight,
                        color: Colors.indigo,
                      ),
                    ), // bot
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 200,
              width: double.infinity,
            ),
            AnimatedBuilder(
              animation: Listenable.merge(
                [
                  _xController,
                  _yController,
                  _zController,
                ],
              ),
              builder: (context, child) => Transform(
                transform: Matrix4.identity()
                  ..rotateX(_animation.evaluate(_xController))
                  ..rotateY(_animation.evaluate(_yController))
                  ..rotateZ(_animation.evaluate(_zController)),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // back
                    Container(
                      width: widthAndHeight,
                      height: widthAndHeight,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      transform: Matrix4.identity()
                        ..translate(
                          Vector3(0, 0, -widthAndHeight),
                        ),
                    ),
                    // left side
                    Transform(
                      transform: Matrix4.identity()
                        ..rotateY(
                          (pi / 2),
                        ),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: widthAndHeight,
                        height: widthAndHeight,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // right side
                    Transform(
                      transform: Matrix4.identity()
                        ..rotateY(
                          -(pi / 2),
                        ),
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: widthAndHeight,
                        height: widthAndHeight,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // front
                    Container(
                      width: widthAndHeight,
                      height: widthAndHeight,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                    // top side
                    Transform(
                      transform: Matrix4.identity()
                        ..rotateX(
                          -(pi / 2),
                        ),
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: widthAndHeight,
                        height: widthAndHeight,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // bottom side
                    Transform(
                      transform: Matrix4.identity()
                        ..rotateX(
                          -(pi / 2),
                        ),
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: widthAndHeight,
                        height: widthAndHeight,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ), // bot
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
