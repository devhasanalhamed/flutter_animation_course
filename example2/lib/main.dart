import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

enum CircleSide {
  left,
  right,
}

extension ToPath on CircleSide {
  Path toPath(Size size) {
    final path = Path();

    late Offset offset;
    late bool clockWise;

    switch (this) {
      case CircleSide.left:
        path.moveTo(size.width, 0);
        offset = Offset(size.width, size.height);
        clockWise = false;
      case CircleSide.right:
        // usually a pencil starts from 0,0 so no need to the code below
        path.moveTo(0, 0);
        offset = Offset(0, size.height);
        clockWise = true;
    }
    // draw an arc function taking a point for radius which is the center
    // of rectangle
    path.arcToPoint(
      offset,
      radius: Radius.elliptical(
        size.width / 2,
        size.height / 2,
      ),
      clockwise: clockWise,
    );

    // this important function will close the drawing to get a half
    // circle either way it's only the arc
    path.close();
    return path;
  }
}

// the job of this class is to bring drawing to life
class HalfCircleClipper extends CustomClipper<Path> {
  final CircleSide side;

  const HalfCircleClipper({
    required this.side,
  });

  @override
  Path getClip(Size size) => side.toPath(size);

  // function tells you changes happened to the parent widget, do you want to rebuild,
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

extension on VoidCallback {
  Future<void> delayed(Duration duration) {
    return Future.delayed(
      duration,
      this,
    );
  }
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _counterClockWiseRotationController;
  late Animation<double> _counterClockWiseRotationAnimation;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  late AnimationController _cubeResizeController;
  late Animation<double> _cubeAnimation;

  @override
  void initState() {
    _counterClockWiseRotationController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 1,
      ),
    );

    _counterClockWiseRotationAnimation = Tween<double>(
      begin: 0.0,
      end: -(pi / 2),
    ).animate(
      CurvedAnimation(
        parent: _counterClockWiseRotationController,
        curve: Curves.bounceOut,
      ),
    );

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 1,
      ),
    );

    _flipAnimation = Tween<double>(
      begin: 0,
      end: pi,
    ).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.bounceOut,
      ),
    );

    // status listener
    _counterClockWiseRotationController.addStatusListener(
      (status) {
        if (status == AnimationStatus.completed) {
          _flipAnimation = Tween<double>(
            begin: _flipAnimation.value,
            end: _flipAnimation.value + pi,
          ).animate(
            CurvedAnimation(
              parent: _flipController,
              curve: Curves.bounceOut,
            ),
          );

          _flipController
            ..reset()
            ..forward();
        }
      },
    );

    _flipController.addStatusListener(
      (status) {
        if (status == AnimationStatus.completed) {
          _counterClockWiseRotationAnimation = Tween<double>(
            begin: _counterClockWiseRotationAnimation.value,
            end: _counterClockWiseRotationAnimation.value + -(pi / 2),
          ).animate(
            CurvedAnimation(
              parent: _counterClockWiseRotationController,
              curve: Curves.bounceOut,
            ),
          );
          _counterClockWiseRotationController
            ..reset()
            ..forward();
        }
      },
    );

    _cubeResizeController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 3,
      ),
    );

    _cubeAnimation = Tween<double>(
      begin: 10,
      end: 100,
    ).animate(_cubeResizeController);

    _cubeResizeController.repeat(reverse: true);

    super.initState();
  }

  @override
  void dispose() {
    _counterClockWiseRotationController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _counterClockWiseRotationController
      ..reset()
      ..forward.delayed(
        const Duration(
          seconds: 1,
        ),
      );

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            AnimatedBuilder(
                animation: _counterClockWiseRotationAnimation,
                builder: (context, child) => Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..rotateZ(_counterClockWiseRotationAnimation.value),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _flipAnimation,
                            builder: (context, child) => Transform(
                              alignment: Alignment.centerRight,
                              transform: Matrix4.identity()
                                ..rotateY(_flipAnimation.value),
                              child: ClipPath(
                                clipper: const HalfCircleClipper(
                                    side: CircleSide.left),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: const BoxDecoration(
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _flipController,
                            builder: (context, child) => Transform(
                              alignment: Alignment.centerLeft,
                              transform: Matrix4.identity()
                                ..rotateY(_flipAnimation.value),
                              child: ClipPath(
                                clipper: const HalfCircleClipper(
                                    side: CircleSide.right),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: const BoxDecoration(
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
            const SizedBox(height: 32.0),
            AnimatedBuilder(
              animation: _cubeResizeController,
              builder: (context, child) => Container(
                width: _cubeAnimation.value,
                height: _cubeAnimation.value,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(
                    15.0,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
