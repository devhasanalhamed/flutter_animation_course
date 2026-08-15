// Capture harness for the vault note on TweenAnimationBuilder.
//
//   flutter run -t lib/tween_demo.dart --dart-define=DEMO=cycle
//   flutter run -t lib/tween_demo.dart --dart-define=DEMO=clip
//   flutter run -t lib/tween_demo.dart --dart-define=DEMO=alpha
//   flutter run -t lib/tween_demo.dart --dart-define=DEMO=badtween
//
//   cycle    - main.dart's behaviour, at a smaller size so it crops well
//   clip     - the same frame with and without ClipPath
//   alpha    - what BlendMode.srcATop actually keys off
//   badtween - Tween<Color> instead of ColorTween, to capture the real error
//
// No timeDilation here: the colour transition is already a full second, and
// mixing dilated animations with wall-clock delays caused a desync while
// capturing the previous note.
//
// main.dart is left untouched: the note points out that its ColorTween
// `begin:` is re-rolled every build and then discarded, so the code has to
// stay as written for the note to be about it.

import 'package:flutter/material.dart';

import 'main.dart' show CircleClipper, getRandomColor;

const demo = String.fromEnvironment('DEMO', defaultValue: 'cycle');

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const screens = <String, Widget>{
      'cycle': CycleDemo(),
      'clip': ClipDemo(),
      'alpha': AlphaDemo(),
      'badtween': BadTweenDemo(),
    };
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: screens[demo] ?? const CycleDemo(),
    );
  }
}

Widget _shell(String title, Widget body) => Scaffold(
      backgroundColor: const Color(0xFF11151C),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        backgroundColor: const Color(0xFF1B2130),
      ),
      body: body,
    );

class _Cap extends StatelessWidget {
  const _Cap(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
      );
}

// ------------------------------------------------------------ the real thing

class CycleDemo extends StatefulWidget {
  const CycleDemo({super.key});

  @override
  State<CycleDemo> createState() => _CycleDemoState();
}

class _CycleDemoState extends State<CycleDemo> {
  var _color = getRandomColor();

  @override
  Widget build(BuildContext context) {
    return _shell(
      'ColorTween cycling forever via onEnd',
      Center(
        child: ClipPath(
          clipper: const CircleClipper(),
          child: TweenAnimationBuilder(
            tween: ColorTween(begin: getRandomColor(), end: _color),
            onEnd: () => setState(() => _color = getRandomColor()),
            duration: const Duration(seconds: 1),
            child: const SizedBox(
              width: 300,
              height: 300,
              child: ColoredBox(color: Colors.red),
            ),
            builder: (context, Color? color, child) => ColorFiltered(
              colorFilter: ColorFilter.mode(color!, BlendMode.srcATop),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ clip or no clip

class ClipDemo extends StatelessWidget {
  const ClipDemo({super.key});

  static const _swatch = Color(0xFF2E9BD6);

  Widget get _square => const SizedBox(
        width: 150,
        height: 150,
        child: ColoredBox(color: _swatch),
      );

  @override
  Widget build(BuildContext context) {
    return _shell(
      'the clipper is the only thing making it round',
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _Cap('without ClipPath'),
            _square,
            const SizedBox(height: 28),
            const _Cap('with ClipPath(clipper: CircleClipper())'),
            ClipPath(clipper: const CircleClipper(), child: _square),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------- what srcATop actually keys off

class AlphaDemo extends StatelessWidget {
  const AlphaDemo({super.key});

  static const _tint = Color(0xFF23C552);

  Widget _panel(String caption, Widget child) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 150, child: _Cap(caption)),
          ColorFiltered(
            colorFilter: const ColorFilter.mode(_tint, BlendMode.srcATop),
            child: SizedBox(width: 110, height: 110, child: child),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return _shell(
      'BlendMode.srcATop paints only where the child is opaque',
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Wrap(
              spacing: 18,
              runSpacing: 18,
              alignment: WrapAlignment.center,
              children: [
                _panel('opaque red child', const ColoredBox(color: Colors.red)),
                _panel('opaque GREEN child\n(identical result)',
                    const ColoredBox(color: Colors.green)),
                _panel(
                  'child with transparency\n(only the disc is tinted)',
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                _panel('fully transparent child\n(nothing to paint on)',
                    const ColoredBox(color: Colors.transparent)),
              ],
            ),
            const SizedBox(height: 22),
            const SizedBox(
              width: 300,
              child: Text(
                'the tint is the SAME green in all four;\n'
                'the base colour never survives, only its alpha matters',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------- Tween<Color> instead of ColorTween

class BadTweenDemo extends StatelessWidget {
  const BadTweenDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _shell(
      'Tween<Color> cannot lerp colours',
      Center(
        // A plain Tween cannot interpolate Color: Tween.lerp computes
        // begin + (end - begin) * t, and Color has no such operators.
        //
        // The duration is deliberately long. Tween.transform short-circuits
        // at t == 0 and t == 1, returning begin/end without ever calling
        // lerp — so a short animation is already settled (and looks fine) by
        // the time a capture lands. The failure only exists in between.
        child: TweenAnimationBuilder<Color?>(
          tween: Tween<Color?>(begin: Colors.red, end: Colors.blue),
          duration: const Duration(seconds: 120),
          builder: (context, color, child) => SizedBox(
            width: 200,
            height: 200,
            child: ColoredBox(color: color ?? Colors.black),
          ),
        ),
      ),
    );
  }
}
