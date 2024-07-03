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
              height: 100,
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
                    // front
                    Container(
                      width: widthAndHeight,
                      height: widthAndHeight,
                      color: Colors.red,
                    ),
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
                    Container(
                      width: widthAndHeight,
                      height: widthAndHeight,
                      color: Colors.purple,
                    ),
                    Container(
                      width: widthAndHeight,
                      height: widthAndHeight,
                      color: Colors.green,
                    ),
                    Container(
                      width: widthAndHeight,
                      height: widthAndHeight,
                      color: Colors.teal,
                    ),
                    Container(
                      width: widthAndHeight,
                      height: widthAndHeight,
                      color: Colors.white,
                    ),
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
