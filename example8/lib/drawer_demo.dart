// Lab harness for the note on example8 (3D drawer).
// main.dart is NOT modified; `MyDrawer` is imported from it so every capture
// of the "real" behaviour runs the lesson's own code.
//
//   flutter run -t lib/drawer_demo.dart --dart-define=DEMO=real
//   DEMO = real | order | hinge | fling | ticker | probe
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'main.dart' show MyDrawer;

const String demo = String.fromEnvironment('DEMO', defaultValue: 'real');

void main() => runApp(const DemoApp());

/// Injects real pointer events into the real gesture pipeline, so the
/// gesture arena, kTouchSlop and DragEndDetails.velocity all behave normally.
class Touch {
  Touch._();
  static int _next = 1;
  static final Stopwatch _clock = Stopwatch()..start();

  static Future<void> drag(
    Offset from,
    Offset to, {
    int steps = 24,
    int stepMs = 16,
    bool release = true,
  }) async {
    final int id = _next++;
    final GestureBinding binding = GestureBinding.instance;
    binding.handlePointerEvent(
      PointerDownEvent(
        pointer: id,
        position: from,
        timeStamp: _clock.elapsed,
        kind: PointerDeviceKind.touch,
      ),
    );
    Offset prev = from;
    for (int i = 1; i <= steps; i++) {
      await Future<void>.delayed(Duration(milliseconds: stepMs));
      final Offset p = Offset.lerp(from, to, i / steps)!;
      binding.handlePointerEvent(
        PointerMoveEvent(
          pointer: id,
          position: p,
          delta: p - prev,
          timeStamp: _clock.elapsed,
          kind: PointerDeviceKind.touch,
        ),
      );
      prev = p;
    }
    if (release) {
      binding.handlePointerEvent(
        PointerUpEvent(
          pointer: id,
          position: prev,
          timeStamp: _clock.elapsed,
          kind: PointerDeviceKind.touch,
        ),
      );
    }
  }

  static Future<void> tap(Offset at) async {
    final int id = _next++;
    final GestureBinding binding = GestureBinding.instance;
    binding.handlePointerEvent(
      PointerDownEvent(
        pointer: id,
        position: at,
        timeStamp: _clock.elapsed,
        kind: PointerDeviceKind.touch,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 60));
    binding.handlePointerEvent(
      PointerUpEvent(
        pointer: id,
        position: at,
        timeStamp: _clock.elapsed,
        kind: PointerDeviceKind.touch,
      ),
    );
  }
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: switch (demo) {
        'grid_order' => const GridPage(kind: 'order'),
        'grid_hinge' => const GridPage(kind: 'hinge'),
        'order' => const ComparePage(kind: 'order'),
        'hinge' => const ComparePage(kind: 'hinge'),
        'fling' => const FlingPage(),
        'ticker' => const TickerPage(),
        'probe' => const ProbePage(),
        _ => const RealPage(),
      },
    );
  }
}

Widget demoPage(String title) => Scaffold(
  appBar: AppBar(title: Text(title)),
  body: const Center(
    child: Text('page', style: TextStyle(color: Colors.white24)),
  ),
);

/// A page with legible edges, so the comparison demos show geometry rather
/// than two dark rectangles on a dark background.
Widget panelPage() => Material(
  child: Container(
    color: const Color(0xFF3D59A1),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(height: 3, color: Colors.white),
        const Spacer(),
        const Text('PAGE', style: TextStyle(fontSize: 26, letterSpacing: 3)),
        const Spacer(),
        Container(height: 3, color: Colors.white),
      ],
    ),
  ),
);

Widget demoDrawer({double leftPad = 80, double topPad = 100}) => Material(
  child: Container(
    color: const Color(0xFF24283B),
    child: ListView.builder(
      padding: EdgeInsets.only(left: leftPad, top: topPad),
      itemCount: 20,
      itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
    ),
  ),
);

// ------------------------------------------- DEMO=grid_hinge | DEMO=grid_order
// One screenshot, no animation: every cell is the same widget frozen at a
// stated controller value, so the reader compares down a column.
class GridPage extends StatelessWidget {
  const GridPage({super.key, required this.kind});
  final String kind; // 'hinge' | 'order'

  static const List<double> values = <double>[0.35, 0.70, 1.00];

  @override
  Widget build(BuildContext context) {
    final bool order = kind == 'order';
    final MediaQueryData mq = MediaQuery.of(context);

    Widget cell(double v, {bool swap = false, Alignment? hinge, required Size size}) {
      return Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          color: const Color(0xFF1A1B26),
        ),
        child: MediaQuery(
          data: mq.copyWith(size: size),
          child: ClipRect(
            child: DrivenDrawer(
              progress: AlwaysStoppedAnimation<double>(v),
              swapOrder: swap,
              childHinge: hinge ?? Alignment.centerLeft,
              drawer: gridDrawer(),
              child: gridPage(),
            ),
          ),
        ),
      );
    }

    Widget rowLabel(String text) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14, bottom: 6),
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Colors.amber, width: 4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.amber,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF15161E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double gap = 10;
              final double w = (constraints.maxWidth - gap * 2) / 3;
              final Size size = Size(w, w * 2.45);

              Widget header() => Row(
                children: <Widget>[
                  for (int i = 0; i < values.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: gap),
                    SizedBox(
                      width: w,
                      child: Text(
                        'value = ${values[i].toStringAsFixed(2)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ],
              );

              Widget row({bool swap = false, Alignment? hinge}) => Row(
                children: <Widget>[
                  for (int i = 0; i < values.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: gap),
                    cell(values[i], swap: swap, hinge: hinge, size: size),
                  ],
                ],
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    order
                        ? 'Matrix4 cascade order'
                        : 'Transform alignment = the hinge',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  header(),
                  const SizedBox(height: 6),
                  rowLabel(order ? 'translate -> rotateY' : 'alignment: centerLeft'),
                  row(),
                  rowLabel(order ? 'rotateY -> translate' : 'alignment: center'),
                  row(
                    swap: order,
                    hinge: order ? null : Alignment.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Page slab for the grid cells: unmistakable edges, one big word.
Widget gridPage() => Material(
  child: Container(
    color: const Color(0xFF3D59A1),
    child: Column(
      children: <Widget>[
        Container(height: 4, color: Colors.white),
        const Spacer(),
        // Hugs the hinge edge: when the page swings away the label leaves the
        // frame whole instead of being sliced down the middle.
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 12),
            child: Text(
              'PAGE',
              style: TextStyle(
                fontSize: 20,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const Spacer(),
        Container(height: 4, color: Colors.white),
      ],
    ),
  ),
);

/// Drawer slab for the grid cells. The drawer slides in from -screenWidth, so
/// anything near its left edge is off-cell for most of the travel; its label
/// therefore hugs the right edge and runs vertically, and the list is drawn as
/// bars. Nothing here can be sliced into half-glyphs by a cell border.
Widget gridDrawer() => Material(
  child: Container(
    color: const Color(0xFF24283B),
    child: Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (final double w in <double>[46, 34, 40])
                  Container(
                    width: w,
                    height: 6,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            const RotatedBox(
              quarterTurns: 3,
              child: Text(
                'DRAWER',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

// ---------------------------------------------------------------- DEMO=real
// The lesson's own MyDrawer, opened and closed by a synthetic finger.
class RealPage extends StatefulWidget {
  const RealPage({super.key});
  @override
  State<RealPage> createState() => _RealPageState();
}

class _RealPageState extends State<RealPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _script());
  }

  Future<void> _script() async {
    final Size s = MediaQuery.of(context).size;
    final double y = s.height / 2;
    for (int i = 0; i < 3; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      await Touch.drag(Offset(12, y), Offset(s.width * 0.8, y), steps: 26);
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      await Touch.drag(Offset(s.width * 0.8, y), Offset(12, y), steps: 26);
    }
  }

  @override
  Widget build(BuildContext context) =>
      MyDrawer(drawer: demoDrawer(), child: demoPage('3D Drawer'));
}

// ------------------------------------------------- DEMO=order | DEMO=hinge
// Two half-width panels driven by one controller, so the only difference
// between them is the thing under test.
class ComparePage extends StatefulWidget {
  const ComparePage({super.key, required this.kind});
  final String kind;
  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    _loop();
  }

  Future<void> _loop() async {
    while (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      await c.forward();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      await c.reverse();
    }
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final double halfW = mq.size.width / 2;
    final bool order = widget.kind == 'order';

    Widget panel(String label, {bool swapOrder = false, Alignment? hinge}) {
      return Expanded(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.amber),
              ),
            ),
            Expanded(
              child: MediaQuery(
                data: mq.copyWith(size: Size(halfW, mq.size.height)),
                child: ClipRect(
                  child: DrivenDrawer(
                    progress: c,
                    swapOrder: swapOrder,
                    childHinge: hinge ?? Alignment.centerLeft,
                    drawer: demoDrawer(leftPad: 24, topPad: 20),
                    child: panelPage(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1B26),
      body: SafeArea(
        child: Row(
          children: order
              ? [
                  panel('translate -> rotateY'),
                  panel('rotateY -> translate', swapOrder: true),
                ]
              : [
                  panel('alignment: centerLeft'),
                  panel('alignment: center', hinge: Alignment.center),
                ],
        ),
      ),
    );
  }
}

/// Same transforms as MyDrawer, but driven by an external progress value
/// and with the two knobs under test exposed.
class DrivenDrawer extends StatelessWidget {
  const DrivenDrawer({
    super.key,
    required this.progress,
    required this.child,
    required this.drawer,
    this.swapOrder = false,
    this.childHinge = Alignment.centerLeft,
  });

  final Animation<double> progress;
  final Widget child;
  final Widget drawer;
  final bool swapOrder;
  final Alignment childHinge;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxDrag = screenWidth * 0.8;

    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final double v = progress.value;
        final double childAngle = v * -pi / 2;
        final double drawerAngle = (1 - v) * pi / 2.7;

        Matrix4 childM = Matrix4.identity()..setEntry(3, 2, 0.001);
        if (swapOrder) {
          childM
            ..rotateY(childAngle)
            ..translateByDouble(v * maxDrag, 0.0, 0.0, 1.0);
        } else {
          childM
            ..translateByDouble(v * maxDrag, 0.0, 0.0, 1.0)
            ..rotateY(childAngle);
        }

        return Stack(
          children: [
            Container(color: const Color(0xFF1A1B26)),
            Transform(
              alignment: childHinge,
              transform: childM,
              child: child,
            ),
            Transform(
              alignment: Alignment.centerRight,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..translateByDouble(-screenWidth + v * maxDrag, 0.0, 0.0, 1.0)
                ..rotateY(drawerAngle),
              child: drawer,
            ),
          ],
        );
      },
    );
  }
}

// --------------------------------------------------------------- DEMO=fling
// Identical fast flick, twice: once into the lesson's threshold-only
// onHorizontalDragEnd, once into a velocity-aware one.
class FlingPage extends StatefulWidget {
  const FlingPage({super.key});
  @override
  State<FlingPage> createState() => _FlingPageState();
}

class _FlingPageState extends State<FlingPage> {
  bool _fixed = false;
  String _label = 'example8:  value < 0.5  ->  reverse()';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _script());
  }

  Future<void> _script() async {
    final Size s = MediaQuery.of(context).size;
    final double y = s.height / 2;
    while (mounted) {
      for (final bool fixed in <bool>[false, true]) {
        setState(() {
          _fixed = fixed;
          _label = fixed
              ? 'DrawerController:  |v| >= 365  ->  fling(velocity)'
              : 'example8:  value < 0.5  ->  reverse()';
        });
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        // ~140 px in ~48 ms  ->  far over _kMinFlingVelocity (365 px/s),
        // but only ~0.44 of maxDrag, so the threshold test says "closed".
        await Touch.drag(Offset(12, y), Offset(152, y), steps: 6, stepMs: 8);
        await Future<void>.delayed(const Duration(milliseconds: 1900));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget page = panelPage();
    final Widget drawer = bigDrawer();
    return Stack(
      children: [
        Positioned.fill(
          child: _fixed
              ? FlingDrawer(drawer: drawer, child: page)
              : MyDrawer(drawer: drawer, child: page),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Container(
            color: const Color(0xF216161E),
            padding: const EdgeInsets.fromLTRB(12, 62, 12, 12),
            child: Column(
              children: <Widget>[
                Text(
                  _label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    height: 1.3,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'same flick both times:  140 px in 48 ms  (~2900 px/s)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// MyDrawer with DrawerController's settle logic instead of the bare
/// 0.5 threshold. Everything else is untouched.
class FlingDrawer extends StatefulWidget {
  const FlingDrawer({super.key, required this.child, required this.drawer});
  final Widget child;
  final Widget drawer;
  @override
  State<FlingDrawer> createState() => _FlingDrawerState();
}

class _FlingDrawerState extends State<FlingDrawer>
    with TickerProviderStateMixin {
  static const double _kMinFlingVelocity = 365.0;

  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> childAngle = Tween<double>(
    begin: 0.0,
    end: -pi / 2,
  ).animate(c);
  late final Animation<double> drawerAngle = Tween<double>(
    begin: pi / 2.7,
    end: 0.0,
  ).animate(c);

  @override
  void dispose() {
    c.dispose();
    super.dispose(); // correct order
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxDrag = screenWidth * 0.8;

    return GestureDetector(
      onHorizontalDragUpdate: (d) => c.value += d.delta.dx / maxDrag,
      onHorizontalDragEnd: (d) {
        final double xVelocity = d.velocity.pixelsPerSecond.dx;
        if (xVelocity.abs() >= _kMinFlingVelocity) {
          c.fling(velocity: xVelocity / maxDrag);
        } else if (c.value < 0.5) {
          c.reverse();
        } else {
          c.forward();
        }
      },
      child: AnimatedBuilder(
        animation: c,
        builder: (context, _) => Stack(
          children: [
            Container(color: const Color(0xFF1A1B26)),
            Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..translateByDouble(c.value * maxDrag, 0.0, 0.0, 1.0)
                ..rotateY(childAngle.value),
              child: widget.child,
            ),
            Transform(
              alignment: Alignment.centerRight,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..translateByDouble(
                  -screenWidth + c.value * maxDrag,
                  0.0,
                  0.0,
                  1.0,
                )
                ..rotateY(drawerAngle.value),
              child: widget.drawer,
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- DEMO=ticker
// Remove the widget while its controllers are still animating, once with the
// lesson's super.dispose()-first order and once with the corrected order.
class TickerPage extends StatefulWidget {
  const TickerPage({super.key});
  @override
  State<TickerPage> createState() => _TickerPageState();
}

class _TickerPageState extends State<TickerPage> {
  int _stage = 0; // 0 none, 1 buggy mounted, 2 fixed mounted
  int _variant = 1; // which variant the current run is testing
  final Map<String, String> _result = <String, String>{};

  @override
  void initState() {
    super.initState();
    final FlutterExceptionHandler? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final String key = _variant == 1 ? 'buggy' : 'fixed';
      final String text = details.exception.toString();
      // ignore: avoid_print
      print('CAPTURED[$key] $text');
      if (text.contains('Ticker')) {
        final List<String> lines = text.split('\n');
        _result[key] = lines.take(2).join('\n');
      }
      previous?.call(details);
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _script());
  }

  Future<void> _runOnce(int stage) async {
    _variant = stage;
    final Size s = MediaQuery.of(context).size;
    final double y = s.height / 2;
    setState(() => _stage = stage);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    // Drag past half and release: forward() starts a 500 ms animation.
    await Touch.drag(Offset(12, y), Offset(s.width * 0.6, y), steps: 12);
    // Rip the widget out while both tickers are still running.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    setState(() => _stage = 0);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _result.putIfAbsent(stage == 1 ? 'buggy' : 'fixed', () => 'no error');
    setState(() {});
  }

  Future<void> _script() async {
    await _runOnce(1);
    await _runOnce(2);
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == 1) {
      return MyDrawer(drawer: demoDrawer(), child: demoPage('buggy dispose'));
    }
    if (_stage == 2) {
      return FixedDisposeDrawer(
        drawer: demoDrawer(),
        child: demoPage('fixed dispose'),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B26),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'dispose() order, widget removed mid-animation',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 18),
              for (final String k in <String>['buggy', 'fixed'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        k == 'buggy'
                            ? 'super.dispose() first (example8)'
                            : 'controllers first (correct)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _result[k] ?? '(running)',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: (_result[k] ?? '').startsWith('no error')
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// MyDrawer with the dispose order corrected.
class FixedDisposeDrawer extends StatefulWidget {
  const FixedDisposeDrawer({
    super.key,
    required this.child,
    required this.drawer,
  });
  final Widget child;
  final Widget drawer;
  @override
  State<FixedDisposeDrawer> createState() => _FixedDisposeDrawerState();
}

class _FixedDisposeDrawerState extends State<FixedDisposeDrawer>
    with TickerProviderStateMixin {
  late final AnimationController xControllerForChild = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final AnimationController xControllerForDrawer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> childAngle = Tween<double>(
    begin: 0.0,
    end: -pi / 2,
  ).animate(xControllerForChild);
  late final Animation<double> drawerAngle = Tween<double>(
    begin: pi / 2.7,
    end: 0.0,
  ).animate(xControllerForDrawer);

  @override
  void dispose() {
    xControllerForChild.dispose();
    xControllerForDrawer.dispose();
    super.dispose(); // <- last
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxDrag = screenWidth * 0.8;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final double delta = details.delta.dx / maxDrag;
        xControllerForChild.value += delta;
        xControllerForDrawer.value += delta;
      },
      onHorizontalDragEnd: (details) {
        if (xControllerForChild.value < 0.5) {
          xControllerForChild.reverse();
          xControllerForDrawer.reverse();
        } else {
          xControllerForChild.forward();
          xControllerForDrawer.forward();
        }
      },
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          xControllerForChild,
          xControllerForDrawer,
        ]),
        builder: (context, _) => Stack(
          children: [
            Container(color: const Color(0xFF1A1B26)),
            Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..translateByDouble(
                  xControllerForChild.value * maxDrag,
                  0.0,
                  0.0,
                  1.0,
                )
                ..rotateY(childAngle.value),
              child: widget.child,
            ),
            Transform(
              alignment: Alignment.centerRight,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..translateByDouble(
                  -screenWidth + xControllerForDrawer.value * maxDrag,
                  0.0,
                  0.0,
                  1.0,
                )
                ..rotateY(drawerAngle.value),
              child: widget.drawer,
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- DEMO=probe
// 1. Does the subtree passed through `widget.child` rebuild every frame even
//    though AnimatedBuilder's `child:` parameter is unused?
// 2. Is the page still tappable once it is rotated to -90 degrees?
// 3. Does a horizontal drag that starts on the drawer's ListView still win
//    the gesture arena?
class ProbePage extends StatefulWidget {
  const ProbePage({super.key});
  @override
  State<ProbePage> createState() => _ProbePageState();
}

class _ProbePageState extends State<ProbePage> {
  static int pageBuilds = 0;
  static int listItemBuilds = 0;
  static int stackBuilds = 0;
  String _counts = '(pending)';
  String _tapWhileOpen = '(pending)';
  String _dragFromList = '(pending)';
  int _pageTaps = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _script());
  }

  Future<void> _script() async {
    final Size s = MediaQuery.of(context).size;
    final double y = s.height / 2;
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final int p0 = pageBuilds;
    final int l0 = listItemBuilds;
    final int s0 = stackBuilds;
    await Touch.drag(Offset(12, y), Offset(s.width * 0.8, y), steps: 26);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _counts =
        'Stack rebuilds: ${stackBuilds - s0}   '
        'page rebuilds: ${pageBuilds - p0}   '
        'ListTile rebuilds: ${listItemBuilds - l0}';
    // ignore: avoid_print
    print('PROBE $_counts');

    // Fully open: the page is rotated -90 degrees about its left edge, so its
    // remaining sliver stands at x = 0.8 * width. Try the sliver, then back
    // off to 85% where the page still projects ~23% of its width.
    final List<String> bands = <String>[];
    for (final double v in <double>[0.0, 0.15, 0.3, 0.6, 1.0]) {
      _controller!.value = v;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final List<double> hits = <double>[];
      for (double f = 0.05; f <= 1.001; f += 0.05) {
        final int before = _pageTaps;
        await Touch.tap(Offset(s.width * f, y));
        await Future<void>.delayed(const Duration(milliseconds: 90));
        if (_pageTaps > before) hits.add(f);
      }
      bands.add(
        hits.isEmpty
            ? 'v=$v: 0 of 20 taps reached the page'
            : 'v=$v: ${hits.length}/20 hit, x/W '
                  '${hits.first.toStringAsFixed(2)}..'
                  '${hits.last.toStringAsFixed(2)}',
      );
    }
    _tapWhileOpen = bands.join('\n');

    // Drag starting on the drawer's ListView, closing direction. Watch the
    // lowest value reached, not the value after the settle.
    _controller!.value = 1.0;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _minSeen = 1.0;
    await Touch.drag(Offset(s.width * 0.4, y), Offset(12, y), steps: 20);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _dragFromList =
        'drag on the ListView: min value ${_minSeen.toStringAsFixed(2)}, '
        'settled at ${_open.toStringAsFixed(2)}';
    // ignore: avoid_print
    print('PROBE $_tapWhileOpen | $_dragFromList');
    setState(() {});
  }

  double _open = 0;
  double _minSeen = 1.0;
  AnimationController? _controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: ProbeDrawer(
            onController: (AnimationController c) => _controller = c,
            onValue: (double v) {
              _open = v;
              if (v < _minSeen) _minSeen = v;
            },
            drawer: Material(
              child: Container(
                color: const Color(0xFF24283B),
                child: ListView.builder(
                  padding: const EdgeInsets.only(left: 80, top: 100),
                  itemCount: 20,
                  itemBuilder: (context, index) {
                    listItemBuilds++;
                    return ListTile(title: Text('Item $index'));
                  },
                ),
              ),
            ),
            child: Builder(
              builder: (context) {
                pageBuilds++;
                return Scaffold(
                  appBar: AppBar(title: const Text('probe')),
                  body: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _pageTaps++,
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: const Color(0xEE16161E),
            padding: const EdgeInsets.all(10),
            child: Text(
              '$_counts\n$_tapWhileOpen\n$_dragFromList',
              style: const TextStyle(fontSize: 12, color: Colors.amber),
            ),
          ),
        ),
      ],
    );
  }
}

/// MyDrawer plus a value callback, so the probe can read the open fraction.
class ProbeDrawer extends StatefulWidget {
  const ProbeDrawer({
    super.key,
    required this.child,
    required this.drawer,
    required this.onValue,
    required this.onController,
  });
  final Widget child;
  final Widget drawer;
  final ValueChanged<double> onValue;
  final ValueChanged<AnimationController> onController;
  @override
  State<ProbeDrawer> createState() => _ProbeDrawerState();
}

class _ProbeDrawerState extends State<ProbeDrawer>
    with TickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> childAngle = Tween<double>(
    begin: 0.0,
    end: -pi / 2,
  ).animate(c);
  late final Animation<double> drawerAngle = Tween<double>(
    begin: pi / 2.7,
    end: 0.0,
  ).animate(c);

  @override
  void initState() {
    super.initState();
    widget.onController(c);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxDrag = screenWidth * 0.8;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        c.value += details.delta.dx / maxDrag;
        widget.onValue(c.value);
      },
      onHorizontalDragEnd: (details) {
        if (c.value < 0.5) {
          c.reverse();
        } else {
          c.forward();
        }
        widget.onValue(c.value);
      },
      child: AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          widget.onValue(c.value);
          _ProbePageState.stackBuilds++;
          return Stack(
            children: [
              Container(color: const Color(0xFF1A1B26)),
              Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..translateByDouble(c.value * maxDrag, 0.0, 0.0, 1.0)
                  ..rotateY(childAngle.value),
                child: widget.child,
              ),
              Transform(
                alignment: Alignment.centerRight,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..translateByDouble(
                    -screenWidth + c.value * maxDrag,
                    0.0,
                    0.0,
                    1.0,
                  )
                  ..rotateY(drawerAngle.value),
                child: widget.drawer,
              ),
            ],
          );
        },
      ),
    );
  }
}
