// Lab harness for the vault note on example9 (animated prompt).
//
// main.dart is NOT modified. Where the real behaviour is being captured, the
// lesson's own `AnimatedPrompt` / `HomePage` are imported and used as written.
// Where a *fixed* controller value is needed (a value cannot be forced on a
// widget that drives itself), `PromptCard` below reproduces the exact widget
// tree of `AnimatedPrompt.build` but takes its progress from the outside.
//
//   flutter run -t lib/prompt_demo.dart --dart-define=DEMO=restart
//   DEMO = real | restart | grid | shadow | probe | blur
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'main.dart' show AnimatedPrompt, HomePage;

const String demo = String.fromEnvironment('DEMO', defaultValue: 'real');

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: switch (demo) {
        'restart' => const RestartPage(),
        'grid' => const GridPage(),
        'shadow' => const ShadowPage(),
        'probe' => const ProbePage(),
        'blur' => const BlurPage(),
        _ => const HomePage(),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// A copy of AnimatedPrompt's tree, driven from the outside.
// Every number here is copied verbatim from main.dart.
// ---------------------------------------------------------------------------

class PromptCard extends StatelessWidget {
  const PromptCard({
    super.key,
    required this.progress,
    this.title = 'Thank you for your order!',
    this.subTitle = 'Your order will be delivered in 2 days. Enjoy!',
    this.clipShadow = true,
    this.iconFilter,
  });

  final Animation<double> progress;
  final String title;
  final String subTitle;

  /// true  → exactly as main.dart writes it: ClipRRect wraps the shadow.
  /// false → the shadow is painted by a parent, outside the clip.
  final bool clipShadow;
  final FilterQuality? iconFilter;

  static const List<BoxShadow> shadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x33000000), // Colors.black.withValues(alpha: 0.2)
      spreadRadius: 5,
      blurRadius: 7,
      offset: Offset(0, 3),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final Animation<Offset> yDisplacement =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, -0.23),
        ).animate(CurvedAnimation(parent: progress, curve: Curves.easeInOut));

    final Animation<double> iconScale = Tween<double>(
      begin: 7,
      end: 6,
    ).animate(CurvedAnimation(parent: progress, curve: Curves.easeInOut));

    final Animation<double> containerScale = Tween<double>(
      begin: 2.0,
      end: 0.4,
    ).animate(CurvedAnimation(parent: progress, curve: Curves.bounceOut));

    final Widget card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: clipShadow ? shadow : null,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 100,
          minHeight: 100,
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 160.0),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Text(
                    subTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: SlideTransition(
                position: yDisplacement,
                child: ScaleTransition(
                  scale: containerScale,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                    child: ScaleTransition(
                      scale: iconScale,
                      filterQuality: iconFilter,
                      child: const Icon(Icons.check),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (clipShadow) {
      return ClipRRect(borderRadius: BorderRadius.circular(20), child: card);
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: shadow,
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: card),
    );
  }
}

/// Renders `child` as if it owned a whole device screen, then scales the whole
/// thing down to fit `width`. Geometry — and therefore every ratio measured off
/// the screenshot — is identical to the real app, only uniformly smaller.
class MiniScreen extends StatelessWidget {
  const MiniScreen({
    super.key,
    required this.width,
    required this.regionHeight,
    required this.child,
  });

  final double width;
  final double regionHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Size real = MediaQuery.sizeOf(context);
    final double scale = width / real.width;
    return SizedBox(
      width: width,
      height: regionHeight * scale,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: real.width,
          height: regionHeight,
          child: MediaQuery(
            data: MediaQueryData(size: real),
            child: child,
          ),
        ),
      ),
    );
  }
}

Widget strip(String text, {Color color = const Color(0xFFFFC64D), double size = 15}) {
  return Container(
    width: double.infinity,
    color: const Color(0xFF11131A),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    child: Text(
      text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.bold,
        color: color,
        height: 1.25,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// DEMO=restart — the real AnimatedPrompt, with the parent rebuilding under it.
// ---------------------------------------------------------------------------

class RestartPage extends StatefulWidget {
  const RestartPage({super.key});

  @override
  State<RestartPage> createState() => _RestartPageState();
}

class _RestartPageState extends State<RestartPage> {
  int rebuilds = 0;
  int exceptions = 0;

  /// 0 = nobody touches it · 1 = parent churning · 2 = parent quiet again
  int phase = 0;
  Timer? timer;

  static const List<String> headline = <String>[
    'nobody rebuilds the parent',
    'parent setState() every 420 ms',
    'parent stopped rebuilding',
  ];
  static const List<Color> ink = <Color>[
    Color(0xFF9BD6FF),
    Color(0xFFFF6B7A),
    Color(0xFF6BE58F),
  ];
  static const List<Color> bg = <Color>[
    Color(0xFF10202E),
    Color(0xFF3A1216),
    Color(0xFF0E2A16),
  ];

  @override
  void initState() {
    super.initState();
    final FlutterExceptionHandler? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      exceptions++;
      previous?.call(details);
    };
    // Let the prompt play once, undisturbed, before the parent starts churning.
    Timer(const Duration(milliseconds: 2200), _startChurning);
  }

  void _startChurning() {
    setState(() => phase = 1);
    timer = Timer.periodic(const Duration(milliseconds: 420), (Timer t) {
      if (t.tick >= 9) {
        t.cancel();
        setState(() => phase = 2);
        return;
      }
      setState(() => rebuilds++);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B26),
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            color: bg[phase],
            padding: const EdgeInsets.fromLTRB(14, 62, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  headline[phase],
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: ink[phase],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'parent builds: $rebuilds     exceptions thrown: $exceptions',
                  style: const TextStyle(fontSize: 15, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: AnimatedPrompt(
                title: 'Thank you for your order!',
                subTitle: 'Your order will be delivered in 2 days. Enjoy!',
                child: const Icon(Icons.check),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DEMO=grid — the card frozen at four controller values, with the two scales
// printed under each cell.
// ---------------------------------------------------------------------------

class GridPage extends StatelessWidget {
  const GridPage({super.key});

  static const List<double> values = <double>[0.00, 0.36, 0.55, 1.00];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070C),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final double cell = (c.maxWidth - 24) / 2;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int row = 0; row < 2; row++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        for (int col = 0; col < 2; col++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _cell(values[row * 2 + col], cell),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _cell(double t, double width) {
    final Animation<double> progress = AlwaysStoppedAnimation<double>(t);
    final double circle = Tween<double>(begin: 2.0, end: 0.4)
        .animate(CurvedAnimation(parent: progress, curve: Curves.bounceOut))
        .value;
    final double icon = Tween<double>(begin: 7, end: 6)
        .animate(CurvedAnimation(parent: progress, curve: Curves.easeInOut))
        .value;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          strip('controller value = ${t.toStringAsFixed(2)}', size: 16),
          DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: Colors.white24)),
            child: ClipRect(
              child: MiniScreen(
                width: width,
                regionHeight: 520,
                child: ColoredBox(
                  color: const Color(0xFF1A1B26),
                  child: Center(child: PromptCard(progress: progress)),
                ),
              ),
            ),
          ),
          strip(
            'circle  ×${circle.toStringAsFixed(2)}\n'
            'icon     ×${icon.toStringAsFixed(2)}\n'
            'icon on screen  ×${(circle * icon).toStringAsFixed(2)}',
            size: 14,
            color: const Color(0xFF9BD6FF),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DEMO=shadow — the boxShadow, inside and outside the ClipRRect.
// ---------------------------------------------------------------------------

class ShadowPage extends StatelessWidget {
  const ShadowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070C),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final double cell = (c.maxWidth - 24) / 2;
            return Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (final bool clip in <bool>[true, false])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SizedBox(
                        width: cell,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            strip(
                              clip
                                  ? 'as written\nClipRRect > Container(boxShadow)'
                                  : 'fixed\nContainer(boxShadow) > ClipRRect',
                              size: 14,
                              color: clip
                                  ? const Color(0xFFFF6B7A)
                                  : const Color(0xFF6BE58F),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white24),
                              ),
                              child: ClipRect(
                                child: MiniScreen(
                                  width: cell,
                                  regionHeight: 560,
                                  child: ColoredBox(
                                    color: const Color(0xFFB9C0CC),
                                    child: Center(
                                      child: PromptCard(
                                        progress:
                                            const AlwaysStoppedAnimation<double>(
                                              1.0,
                                            ),
                                        clipShadow: clip,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DEMO=probe — who rebuilds per tick, counted by the framework itself.
// `debugPrintRebuildDirtyWidgets` makes Element.rebuild print one line per
// dirty element (framework.dart:5510); debugPrint is redirected into a tally.
// ---------------------------------------------------------------------------

class ProbePage extends StatefulWidget {
  const ProbePage({super.key});

  @override
  State<ProbePage> createState() => _ProbePageState();
}

class _ProbePageState extends State<ProbePage>
    with SingleTickerProviderStateMixin {
  static final Map<String, int> tally = <String, int>{};
  static int ticks = 0;

  late final AnimationController controller;
  bool done = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final DebugPrintCallback previous = debugPrint;
    tally.clear();
    Tally.counts.clear();
    ticks = 0;
    void onTick() => ticks++;
    controller.addListener(onTick);
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message == null) return;
      if (!message.startsWith('Rebuilding ') && !message.startsWith('Building ')) {
        return;
      }
      // 'Rebuilding ScaleTransition(state: _AnimatedState#1a2b3)' → widget type
      final String rest = message.substring(message.indexOf(' ') + 1);
      final int cut = rest.indexOf('(');
      final String name = cut > 0 ? rest.substring(0, cut) : rest;
      tally[name] = (tally[name] ?? 0) + 1;
    };
    debugPrintRebuildDirtyWidgets = true;
    await controller.forward().orCancel;
    debugPrintRebuildDirtyWidgets = false;
    debugPrint = previous;
    controller.removeListener(onTick);
    if (mounted) setState(() => done = true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    if (done) {
      // Every row is asked for, so a widget that never rebuilt shows a 0
      // instead of quietly vanishing from the list.
      final Map<String, int> rows = <String, int>{
        'SlideTransition': tally['SlideTransition'] ?? 0,
        'ScaleTransition': tally['ScaleTransition'] ?? 0,
        'AnimatedBuilder': tally['AnimatedBuilder'] ?? 0,
        'FadeTransition': tally['FadeTransition'] ?? 0,
        'a child passed as child:': Tally.counts['child of ScaleTransition'] ?? 0,
        'a child built in the builder':
            Tally.counts['built inside AnimatedBuilder'] ?? 0,
        'a Text elsewhere on the page': Tally.counts['static text above'] ?? 0,
      };
      final List<String> keys = rows.keys.toList();
      return Scaffold(
        backgroundColor: const Color(0xFF05070C),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'rebuilds during one 1000 ms run',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFC64D),
                  ),
                ),
                Text(
                  'the controller notified its listeners $ticks times',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 14),
                for (final String k in keys.take(11))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 62,
                          child: Text(
                            '${rows[k]}',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: rows[k]! > 10
                                  ? const Color(0xFFFF6B7A)
                                  : const Color(0xFF6BE58F),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            k,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
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

    return Scaffold(
      backgroundColor: const Color(0xFF1A1B26),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Tally(label: 'static text above'),
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(0, -0.23),
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: 2.0, end: 0.4).animate(curved),
                child: const SizedBox(
                  width: 120,
                  height: 120,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                    child: Tally(label: 'child of ScaleTransition'),
                  ),
                ),
              ),
            ),
            FadeTransition(
              opacity: curved,
              child: const Tally(label: 'child of FadeTransition'),
            ),
            AnimatedBuilder(
              animation: curved,
              builder: (BuildContext context, Widget? child) => Opacity(
                opacity: curved.value,
                // built inside the builder → a new widget instance every tick
                // ignore: prefer_const_constructors
                child: Tally(label: 'built inside AnimatedBuilder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A leaf that counts how many times it is built.
class Tally extends StatefulWidget {
  const Tally({super.key, required this.label});

  final String label;

  static final Map<String, int> counts = <String, int>{};

  @override
  State<Tally> createState() => _TallyState();
}

class _TallyState extends State<Tally> {
  @override
  Widget build(BuildContext context) {
    Tally.counts[widget.label] = (Tally.counts[widget.label] ?? 0) + 1;
    return Text(
      widget.label,
      style: const TextStyle(fontSize: 11, color: Colors.white54),
    );
  }
}

// ---------------------------------------------------------------------------
// DEMO=blur — a glyph magnified by ScaleTransition vs. a glyph laid out large.
// ---------------------------------------------------------------------------

class BlurPage extends StatelessWidget {
  const BlurPage({super.key});

  static const double base = 24.0; // the default Icon size
  static const double factor = 6.0; // iconScaleAnimation at value 1.0

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070C),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _row(
              'ScaleTransition(scale: 6) over Icon(size: 24)\n'
              'filterQuality: null — the default',
              const Color(0xFF6BE58F),
              ScaleTransition(
                scale: const AlwaysStoppedAnimation<double>(factor),
                child: const Icon(Icons.check, size: base, color: Colors.white),
              ),
            ),
            _row(
              'the same, but filterQuality: FilterQuality.medium',
              const Color(0xFFFF6B7A),
              ScaleTransition(
                scale: const AlwaysStoppedAnimation<double>(factor),
                filterQuality: FilterQuality.medium,
                child: const Icon(Icons.check, size: base, color: Colors.white),
              ),
            ),
            _row(
              'Icon(size: 144) — laid out large, never scaled',
              const Color(0xFF9BD6FF),
              const Icon(
                Icons.check,
                size: base * factor,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, Color color, Widget sample) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            color: const Color(0xFF11131A),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          SizedBox(
            height: 170,
            child: Center(child: sample),
          ),
        ],
      ),
    );
  }
}
