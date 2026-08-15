// Capture harness for the vault note on chained explicit animations.
//
// The note's central rule is "decompose the animation before writing a line",
// so each stage is captured on its own here rather than only the finished
// result. Pick a stage at build time:
//
//   flutter run -t lib/stages_demo.dart --dart-define=STAGE=clip
//   flutter run -t lib/stages_demo.dart --dart-define=STAGE=rotate
//   flutter run -t lib/stages_demo.dart --dart-define=STAGE=flip
//
//   clip   - static: two plain squares beside the same pair clipped to a circle
//   rotate - the -90 degree turn with Curves.bounceOut, on its own
//   flip   - the 180 degree rotateY, on its own
//
// main.dart is deliberately left untouched: the note critiques that code as
// written, including its build()-launch and CurvedAnimation leak.

import 'dart:math';

import 'package:flutter/material.dart';

import 'main.dart' show CircleSide, HalfCircleClipper;

const stage = String.fromEnvironment('STAGE', defaultValue: 'rotate');

void main() => runApp(const StagesApp());

class StagesApp extends StatelessWidget {
  const StagesApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark),
        home: stage == 'clip' ? const ClipStage() : const MotionStage(),
      );
}

const _amber = Colors.amber;
const _purple = Colors.deepPurple;
const double _size = 100;

/// Static before/after: plain squares vs the same pair clipped into a circle.
class ClipStage extends StatelessWidget {
  const ClipStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101014),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _Caption('قبل القصّ — حاويتان في Row'),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    width: _size,
                    height: _size,
                    child: ColoredBox(color: _amber)),
                SizedBox(
                    width: _size,
                    height: _size,
                    child: ColoredBox(color: _purple)),
              ],
            ),
            const SizedBox(height: 56),
            const _Caption('بعد القصّ — ClipPath لكل نصف'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipPath(
                  clipper: const HalfCircleClipper(side: CircleSide.left),
                  child: Container(width: _size, height: _size, color: _amber),
                ),
                ClipPath(
                  clipper: const HalfCircleClipper(side: CircleSide.right),
                  child: Container(width: _size, height: _size, color: _purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One motion in isolation, looping with a pause so the capture reads clearly.
class MotionStage extends StatefulWidget {
  const MotionStage({super.key});

  @override
  State<MotionStage> createState() => _MotionStageState();
}

class _MotionStageState extends State<MotionStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation =
        Tween<double>(begin: 0, end: stage == 'flip' ? pi : -(pi / 2)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.bounceOut),
    );
    _loop();
  }

  // Play, hold, reset — so each repetition is legible in a short recording.
  Future<void> _loop() async {
    while (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      await _controller.forward();
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget get _circle => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipPath(
            clipper: const HalfCircleClipper(side: CircleSide.left),
            child: Container(width: _size, height: _size, color: _amber),
          ),
          ClipPath(
            clipper: const HalfCircleClipper(side: CircleSide.right),
            child: Container(width: _size, height: _size, color: _purple),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101014),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final m = Matrix4.identity();
            if (stage == 'flip') {
              m.rotateY(_animation.value);
            } else {
              m.rotateZ(_animation.value);
            }
            return Transform(
              alignment: Alignment.center,
              transform: m,
              child: _circle,
            );
          },
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: Colors.white54, fontSize: 15));
}
