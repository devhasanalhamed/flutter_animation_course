// Capture harness for the vault note on 3D animations.
//
// Same cube as main.dart, but isolated on screen and spinning fast enough that
// a ten-second recording shows a full rotation. Pick a variant at build time:
//
//   flutter run -t lib/cube_demo.dart --dart-define=VARIANT=flat
//   flutter run -t lib/cube_demo.dart --dart-define=VARIANT=depth
//   flutter run -t lib/cube_demo.dart --dart-define=VARIANT=wireframe
//   flutter run -t lib/cube_demo.dart --dart-define=VARIANT=nobottom
//
//   flat      - no perspective term: rotation reads as mirroring, not depth
//   depth     - with setEntry(3, 2, 0.001)
//   wireframe - one colour + borders: exposes the missing backface culling
//   nobottom  - reproduces the duplicated-bottom-face bug for the note
//   compare   - both cubes at once, same rotation, perspective on/off

import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

const variant = String.fromEnvironment('VARIANT', defaultValue: 'depth');

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: const CubePage(),
    );
  }
}

class CubePage extends StatefulWidget {
  const CubePage({super.key});

  @override
  State<CubePage> createState() => _CubePageState();
}

class _CubePageState extends State<CubePage> with TickerProviderStateMixin {
  static const double size = 110;

  late final AnimationController _x;
  late final AnimationController _y;
  late final AnimationController _z;
  final _turn = Tween<double>(begin: 0, end: pi * 2);

  @override
  void initState() {
    super.initState();
    _x = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _y = AnimationController(vsync: this, duration: const Duration(seconds: 6));
    _z = AnimationController(vsync: this, duration: const Duration(seconds: 8));
    _x.repeat();
    _y.repeat();
    _z.repeat();
  }

  @override
  void dispose() {
    _x.dispose();
    _y.dispose();
    _z.dispose();
    super.dispose();
  }

  bool get _wireframe => variant == 'wireframe';

  Widget _face(Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _wireframe ? Colors.amber : color,
          border: _wireframe
              ? Border.all(color: Colors.white, width: 2)
              : Border.all(color: Colors.white24),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101014),
      body: Center(
        child: variant == 'compare'
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _Label('بدون perspective'),
                  SizedBox(height: 220, child: Center(child: _cube(null))),
                  const SizedBox(height: 40),
                  const _Label('setEntry(3, 2, 0.003)'),
                  SizedBox(height: 220, child: Center(child: _cube(0.003))),
                ],
              )
            : _cube(variant == 'flat' ? null : 0.001),
      ),
    );
  }

  Widget _cube(double? perspective) {
    return AnimatedBuilder(
      animation: Listenable.merge([_x, _y, _z]),
      builder: (context, _) {
        final m = Matrix4.identity();
        if (perspective != null) m.setEntry(3, 2, perspective);
        m
          ..rotateX(_turn.evaluate(_x))
          ..rotateY(_turn.evaluate(_y))
          ..rotateZ(_turn.evaluate(_z));

        return Transform(
          alignment: Alignment.center,
          transform: m,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // back
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: _wireframe ? Colors.amber : Colors.amber,
                  border: _wireframe
                      ? Border.all(color: Colors.white, width: 2)
                      : Border.all(color: Colors.white24),
                ),
                transform: Matrix4.identity()
                  ..translateByVector3(Vector3(0, 0, -size)),
              ),
              // left
              Transform(
                transform: Matrix4.identity()..rotateY(pi / 2),
                alignment: Alignment.centerLeft,
                child: _face(Colors.purple),
              ),
              // right
              Transform(
                transform: Matrix4.identity()..rotateY(-(pi / 2)),
                alignment: Alignment.centerRight,
                child: _face(Colors.green),
              ),
              // front
              _face(Colors.red),
              // top
              Transform(
                transform: Matrix4.identity()..rotateX(-(pi / 2)),
                alignment: Alignment.topCenter,
                child: _face(Colors.teal),
              ),
              // bottom — 'nobottom' reproduces the bug: identical to top,
              // so it paints over the top face and leaves the cube open.
              Transform(
                transform: Matrix4.identity()
                  ..rotateX(variant == 'nobottom' ? -(pi / 2) : pi / 2),
                alignment: variant == 'nobottom'
                    ? Alignment.topCenter
                    : Alignment.bottomCenter,
                child: _face(Colors.indigo),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(color: Colors.white54, fontSize: 15),
      );
}
