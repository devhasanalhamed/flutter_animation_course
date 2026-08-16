// Capture harness for the vault note on CustomPainter.
//
//   flutter run -t lib/painter_demo.dart --dart-define=DEMO=sides
//   flutter run -t lib/painter_demo.dart --dart-define=DEMO=repaint
//   flutter run -t lib/painter_demo.dart --dart-define=DEMO=rotation
//
//   sides    - a static 3..10 grid, each drawn in a bordered box so it also
//              shows whether the 3px stroke spills past the layout bounds
//   repaint  - the example's shouldRepaint (sides only) beside a corrected one
//              (sides AND colour), with only the colour animating
//   rotation - X+Y+Z rotation beside Z-only, to isolate what the missing
//              perspective term costs
//
// The faithful capture is taken from main.dart itself, which already drives
// its own controllers, so there is no 'real' variant here.
//
// main.dart is left untouched: the note critiques its didChangeDependencies
// launch and its shouldRepaint, so the code has to stay as written.

import 'package:flutter/material.dart';
import 'dart:math' show pi;

import 'main.dart' show Polygon;

const demo = String.fromEnvironment('DEMO', defaultValue: 'sides');

const edge = Color(0xFF3D4657);

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const screens = <String, Widget>{
      'sides': SidesGrid(),
      'repaint': RepaintDemo(),
      'rotation': RotationDemo(),
      'deps': DepsDemo(),
    };
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: screens[demo] ?? const SidesGrid(),
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

/// Same contract as the example's Polygon, but it also repaints when the
/// colour changes — which is what `paint` actually reads.
class PolygonFixed extends CustomPainter {
  const PolygonFixed({required this.sides, required this.color});

  final int sides;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      Polygon(sides: sides, color: color).paint(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is! PolygonFixed ||
      oldDelegate.sides != sides ||
      oldDelegate.color != color;
}

// ------------------------------------------------------------- 3..10 sides

class SidesGrid extends StatelessWidget {
  const SidesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return _shell(
      'what IntTween(3 -> 10) steps through',
      Center(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              for (var n = 3; n <= 10; n++)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$n',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70)),
                    const SizedBox(height: 4),
                    // The border marks the exact layout bounds, so any stroke
                    // spilling outside the box is visible.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: edge),
                      ),
                      child: CustomPaint(
                        painter: Polygon(sides: n, color: Colors.amber),
                        child: const SizedBox(width: 74, height: 74),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------- shouldRepaint ignoring colour

class RepaintDemo extends StatefulWidget {
  const RepaintDemo({super.key});

  @override
  State<RepaintDemo> createState() => _RepaintDemoState();
}

class _RepaintDemoState extends State<RepaintDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<Color?> _colour;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _colour = ColorTween(begin: Colors.amber, end: Colors.cyan).animate(_c);
    _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _panel(String label, Color labelColour, CustomPainter painter) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 150,
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: labelColour)),
          ),
          const SizedBox(height: 6),
          // RepaintBoundary is load-bearing here. Without it both panels share
          // one layer, so the corrected panel's repaint drags the broken one
          // along with it and the bug is invisible. Isolating the layer is
          // what makes a wrong shouldRepaint actually show.
          RepaintBoundary(
            child: CustomPaint(
              painter: painter,
              child: const SizedBox(width: 130, height: 130),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    // Size and sides are held constant on purpose: a size change would force
    // a repaint on its own and hide the bug.
    return _shell(
      'shouldRepaint that ignores colour',
      Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final c = _colour.value ?? Colors.amber;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _panel(
                  'the example:\nshouldRepaint compares sides only',
                  const Color(0xFFFF8A80),
                  Polygon(sides: 6, color: c),
                ),
                const SizedBox(height: 30),
                _panel(
                  'corrected:\ncompares sides AND colour',
                  const Color(0xFF6BE675),
                  PolygonFixed(sides: 6, color: c),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 260,
                  child: Text(
                    'both are handed the same animated colour',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// --------------------------------- does didChangeDependencies actually re-fire?

/// Counts its own didChangeDependencies calls. [subscribes] decides whether
/// this element subscribes to an InheritedWidget at all.
class DepsProbe extends StatefulWidget {
  const DepsProbe({required this.label, required this.subscribes, super.key});

  final String label;
  final bool subscribes;

  @override
  State<DepsProbe> createState() => _DepsProbeState();
}

class _DepsProbeState extends State<DepsProbe> {
  int _calls = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calls++;
  }

  @override
  Widget build(BuildContext context) {
    // Reading MediaQuery here is what registers the dependency. Without it
    // this element never subscribes, so didChangeDependencies fires once.
    // (MediaQuery, not Theme: the app pins themeMode to dark, so ThemeData
    // never actually changes when the platform appearance flips.)
    final brightness = widget.subscribes
        ? MediaQuery.of(context).platformBrightness.name
        : 'not read';

    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: edge)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text('didChangeDependencies: $_calls',
              style: const TextStyle(
                  fontSize: 15,
                  fontFamily: 'Courier',
                  color: Color(0xFF6BE675))),
          Text('platformBrightness -> $brightness',
              style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }
}

class DepsDemo extends StatelessWidget {
  const DepsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _shell(
      'when does didChangeDependencies re-fire?',
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const DepsProbe(
              label: 'like the example:\nbuild reads no InheritedWidget',
              subscribes: false,
            ),
            const SizedBox(height: 22),
            const DepsProbe(
              label: 'same widget, but build calls MediaQuery.of(context)',
              subscribes: true,
            ),
            const SizedBox(height: 22),
            const SizedBox(
              width: 280,
              child: Text(
                'toggle the simulator appearance and compare the counts',
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

// ------------------------------------------------- rotation with no perspective

class RotationDemo extends StatefulWidget {
  const RotationDemo({super.key});

  @override
  State<RotationDemo> createState() => _RotationDemoState();
}

class _RotationDemoState extends State<RotationDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _turn;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _turn = Tween(begin: 0.0, end: 2 * pi)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_c);
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _panel(String label, Color labelColour, Matrix4 Function(double) m) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: labelColour)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 150,
            height: 150,
            child: Center(
              child: Transform(
                alignment: Alignment.center,
                transform: m(_turn.value),
                child: CustomPaint(
                  painter: Polygon(sides: 6, color: Colors.amber),
                  child: const SizedBox(width: 120, height: 120),
                ),
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return _shell(
      'rotateX/Y/Z with no perspective term',
      Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _panel(
                'the example (top shape):\nrotateX + rotateY + rotateZ',
                const Color(0xFFFF8A80),
                (t) => Matrix4.identity()
                  ..rotateX(t)
                  ..rotateY(t)
                  ..rotateZ(t),
              ),
              const SizedBox(height: 26),
              _panel(
                'the example (bottom shape):\nrotateZ only',
                const Color(0xFF6BE675),
                (t) => Matrix4.identity()..rotateZ(t),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
