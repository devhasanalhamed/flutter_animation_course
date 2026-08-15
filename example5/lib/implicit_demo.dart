// Capture harness for the vault note on implicit animations.
//
//   flutter run -t lib/implicit_demo.dart --dart-define=DEMO=zoom
//   flutter run -t lib/implicit_demo.dart --dart-define=DEMO=interrupt
//   flutter run -t lib/implicit_demo.dart --dart-define=DEMO=compare
//   flutter run -t lib/implicit_demo.dart --dart-define=DEMO=explicit
//
//   zoom      - main.dart's behaviour verbatim, driven on a timer
//   interrupt - toggles mid-flight, to show didUpdateWidget rebasing the tween
//   compare   - bounceOut vs decelerate on an identical width change
//   explicit  - the same motion written implicitly and explicitly, side by side
//
// main.dart is left untouched: the note points out that its `defaultCurve`
// (Curves.bounceIn) never drives a visible transition, so the code has to stay
// as written for the note to be about it.
//
// Taps are driven by timers rather than injected input: simctl/adb tap
// injection proved unreliable, and a timer makes every capture identical.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

const demo = String.fromEnvironment('DEMO', defaultValue: 'zoom');

const image = 'assets/images/city.jpg';
const edge = Color(0xFFFF5252);

void main() {
  // 370 ms is too quick to read in a GIF. The animation is unchanged; only
  // the clock is slowed, and the note says so.
  timeDilation = 3.0;
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const screens = <String, Widget>{
      'zoom': ZoomDemo(),
      'interrupt': InterruptDemo(),
      'compare': CurveCompareDemo(),
      'explicit': ImplicitVsExplicitDemo(),
    };
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: screens[demo] ?? const ZoomDemo(),
    );
  }
}

/// Waits in ANIMATION time, not wall-clock time.
///
/// timeDilation stretches animations but not `Future.delayed`, so a
/// choreography written in raw milliseconds silently desynchronises: a 700 ms
/// animation really takes 2100 ms and a 1600 ms wait cuts it off mid-flight.
Future<void> _wait(int ms) =>
    Future<void>.delayed(Duration(milliseconds: (ms * timeDilation).round()));

Widget _shell(String title, Widget body) => Scaffold(
      backgroundColor: const Color(0xFF11151C),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 15)),
        backgroundColor: const Color(0xFF1B2130),
      ),
      body: body,
    );

class _Label extends StatelessWidget {
  const _Label(this.text, {this.colour = Colors.white});

  final String text;
  final Color colour;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colour),
      );
}

// ------------------------------------------------- main.dart, driven by timer

const double defaultWidth = 200;
const Curve defaultCurve = Curves.bounceIn;

class ZoomDemo extends StatefulWidget {
  const ZoomDemo({super.key});

  @override
  State<ZoomDemo> createState() => _ZoomDemoState();
}

class _ZoomDemoState extends State<ZoomDemo> {
  var isZoomedIn = false;
  var width = defaultWidth;
  var curve = defaultCurve;

  @override
  void initState() {
    super.initState();
    _loop();
  }

  Future<void> _loop() async {
    while (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      if (!mounted) return;
      _toggle();
    }
  }

  void _toggle() {
    setState(() {
      isZoomedIn = !isZoomedIn;
      width = isZoomedIn ? MediaQuery.of(context).size.width : defaultWidth;
      curve = isZoomedIn ? Curves.bounceOut : Curves.decelerate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _shell(
      'AnimatedContainer - width only',
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16.0,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 370),
                width: width,
                curve: curve,
                child: Image.asset(image),
              ),
            ],
          ),
          Text(isZoomedIn ? 'Zoom Out' : 'Zoom In'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------- interrupting mid-flight

class InterruptDemo extends StatefulWidget {
  const InterruptDemo({super.key});

  @override
  State<InterruptDemo> createState() => _InterruptDemoState();
}

class _InterruptDemoState extends State<InterruptDemo> {
  static const _small = 90.0;
  static const _large = 300.0;
  static const _duration = Duration(milliseconds: 900);

  double _width = _small;
  String _phase = '';

  @override
  void initState() {
    super.initState();
    _loop();
  }

  // Go wide, then flip back BEFORE the first move finishes. The reversal
  // starts from wherever the width currently is, because didUpdateWidget
  // rebases begin to tween.evaluate(_animation).
  Future<void> _loop() async {
    while (mounted) {
      await _set(_large, 'growing to 300...');
      // Cut in at ~40% of the 900 ms animation, well before it lands.
      await _wait(370);
      if (!mounted) return;
      await _set(_small, 'INTERRUPTED mid-flight -> back to 90');
      // Let the reversal finish, then hold so the loop reads cleanly.
      await _wait(1500);
    }
  }

  Future<void> _set(double w, String phase) async {
    if (!mounted) return;
    setState(() {
      _width = w;
      _phase = phase;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _shell(
      'interrupting an implicit animation',
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Label(_phase, colour: const Color(0xFF6BE675)),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: _duration,
              curve: Curves.easeInOut,
              width: _width,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7DD1),
                border: Border.all(color: edge),
              ),
            ),
            const SizedBox(height: 12),
            const _Label(
              'the reversal starts from the CURRENT width,\nnot from 300',
              colour: Colors.white60,
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------- bounceOut vs decelerate

class CurveCompareDemo extends StatefulWidget {
  const CurveCompareDemo({super.key});

  @override
  State<CurveCompareDemo> createState() => _CurveCompareDemoState();
}

class _CurveCompareDemoState extends State<CurveCompareDemo> {
  bool _big = false;

  @override
  void initState() {
    super.initState();
    _loop();
  }

  Future<void> _loop() async {
    while (mounted) {
      // Longer than the 700 ms animation, so each curve lands and holds
      // before the next change — otherwise the bounce is never visible.
      await _wait(1150);
      if (!mounted) return;
      setState(() => _big = !_big);
    }
  }

  Widget _bar(String label, Curve curve, Color colour) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(label, colour: colour),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            curve: curve,
            width: _big ? 320 : 90,
            height: 70,
            decoration: BoxDecoration(
              color: colour,
              border: Border.all(color: edge),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return _shell(
      'the same change, two curves',
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar('Curves.bounceOut', Curves.bounceOut, const Color(0xFF2E7DD1)),
            const SizedBox(height: 26),
            _bar('Curves.decelerate', Curves.decelerate, const Color(0xFF8E6BD4)),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------- implicit vs explicit

class ImplicitVsExplicitDemo extends StatefulWidget {
  const ImplicitVsExplicitDemo({super.key});

  @override
  State<ImplicitVsExplicitDemo> createState() => _ImplicitVsExplicitDemoState();
}

class _ImplicitVsExplicitDemoState extends State<ImplicitVsExplicitDemo>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 700);
  static const _small = 90.0;
  static const _large = 320.0;

  // implicit: one field
  bool _big = false;

  // explicit: a controller, a tween, a builder, and a dispose
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _animation = Tween<double>(begin: _small, end: _large).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _loop();
  }

  Future<void> _loop() async {
    while (mounted) {
      await _wait(900);
      if (!mounted) return;
      // The setState drives the implicit bar; the controller drives the
      // explicit one. Both start in the same frame, so they should track.
      setState(() => _big = !_big);
      if (_big) {
        await _controller.forward();
      } else {
        await _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _shell(
      'same motion, both ways',
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Label('implicit - AnimatedContainer', colour: Color(0xFF6BE675)),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: _duration,
              curve: Curves.easeInOut,
              width: _big ? _large : _small,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7DD1),
                border: Border.all(color: edge),
              ),
            ),
            const SizedBox(height: 26),
            const _Label('explicit - AnimationController', colour: Color(0xFFFFB74D)),
            const SizedBox(height: 6),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) => Container(
                width: _animation.value,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF8E6BD4),
                  border: Border.all(color: edge),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
