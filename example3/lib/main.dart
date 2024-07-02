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
  leftSide,
  rightSide,
}

extension ToPath on CircleSide {
  Path toPath(Size size) {
    final path = Path();
    final Offset offset;
    final bool clockwise;

    switch (this) {
      case CircleSide.leftSide:
        path.moveTo(size.width, 0);
        offset = Offset(size.width, size.height);
        clockwise = false;
      case CircleSide.rightSide:
        path.moveTo(0, 0);
        offset = Offset(0, size.height);
        clockwise = true;
    }

    path.arcToPoint(
      offset,
      radius: Radius.elliptical(
        size.width / 2,
        size.height / 2,
      ),
      clockwise: clockwise,
    );

    path.close();
    return path;
  }
}

class HalfCircleClipper extends CustomClipper<Path> {
  final CircleSide circleSide;

  const HalfCircleClipper(
    this.circleSide,
  );

  @override
  Path getClip(Size size) => circleSide.toPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _counterClockwiseRotationController;
  late Animation<double> _counterClockwiseRotationAnimation;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  late AnimationController _loadingAnimationController;
  late Animation<double> _loadingAnimation1;
  late Animation<double> _loadingAnimation2;
  late Animation<double> _loadingAnimation3;

  @override
  void initState() {
    _counterClockwiseRotationController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 1,
      ),
    );

    _counterClockwiseRotationAnimation = Tween<double>(
      begin: 0.0,
      end: -(pi / 2),
    ).animate(
      CurvedAnimation(
        parent: _counterClockwiseRotationController,
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
      begin: 0.0,
      end: pi,
    ).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.bounceOut,
      ),
    );

    _counterClockwiseRotationAnimation.addStatusListener(
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

    _flipAnimation.addStatusListener(
      (status) {
        if (status == AnimationStatus.completed) {
          _counterClockwiseRotationAnimation = Tween<double>(
            begin: _counterClockwiseRotationAnimation.value,
            end: _counterClockwiseRotationAnimation.value + -(pi / 2),
          ).animate(
            CurvedAnimation(
              parent: _counterClockwiseRotationController,
              curve: Curves.bounceOut,
            ),
          );
          _counterClockwiseRotationController
            ..reset()
            ..forward();
        }
      },
    );

    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 1,
      ),
    );

    _loadingAnimation1 = Tween<double>(
      begin: 0.0,
      end: 50.0,
    ).animate(_loadingAnimationController);

    _loadingAnimation2 = Tween<double>(
      begin: 0.0,
      end: 75.0,
    ).animate(_loadingAnimationController);

    _loadingAnimation3 = Tween<double>(
      begin: 0.0,
      end: 100.0,
    ).animate(_loadingAnimationController);

    _loadingAnimationController.repeat(
      reverse: true,
    );

    super.initState();
  }

  @override
  void dispose() {
    _counterClockwiseRotationController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(
      const Duration(seconds: 1),
      () => _counterClockwiseRotationController.forward(),
    );

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _counterClockwiseRotationController,
              builder: (context, child) => Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateZ(_counterClockwiseRotationAnimation.value),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _flipController,
                      builder: (context, child) => Transform(
                        alignment: Alignment.centerRight,
                        transform: Matrix4.identity()
                          ..rotateY(_flipAnimation.value),
                        child: ClipPath(
                          clipper: const HalfCircleClipper(CircleSide.leftSide),
                          child: Container(
                            height: 100,
                            width: 100,
                            color: Colors.amber,
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
                          clipper:
                              const HalfCircleClipper(CircleSide.rightSide),
                          child: Container(
                            height: 100,
                            width: 100,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            const Divider(),
            const SizedBox(height: 16.0),
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AnimatedBuilder(
                    animation: _loadingAnimationController,
                    builder: (context, child) => Transform(
                      transform: Transform.translate(
                        offset: Offset(
                          0,
                          _loadingAnimation1.value,
                        ),
                      ).transform,
                      child: Container(
                        width: 24.0,
                        height: 24.0,
                        decoration: const BoxDecoration(
                          color: Colors.yellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _loadingAnimationController,
                    builder: (context, child) => Transform(
                      transform: Transform.translate(
                        offset: Offset(
                          0,
                          _loadingAnimation2.value,
                        ),
                      ).transform,
                      child: Container(
                        width: 24.0,
                        height: 24.0,
                        decoration: const BoxDecoration(
                          color: Colors.yellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _loadingAnimationController,
                    builder: (context, child) => Transform(
                      transform: Transform.translate(
                        offset: Offset(
                          0,
                          _loadingAnimation3.value,
                        ),
                      ).transform,
                      child: Container(
                        width: 24.0,
                        height: 24.0,
                        decoration: const BoxDecoration(
                          color: Colors.yellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
