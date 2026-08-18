// Gallery for the vault note `Widgets/Animation/Transitions.md`.
// One AnimationController drives every widget in the `*Transition` family, so
// the figure shows what each one does with the *same* input.
//
//   flutter run -t lib/transitions_gallery.dart
import 'package:flutter/material.dart';

void main() => runApp(const GalleryApp());

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GalleryPage(),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> t;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    t = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  static const Color ink = Color(0xFF05070C);
  static const Color line = Color(0x33FFFFFF);
  static const Color mark = Color(0xFF4FC3F7);

  Widget get _box => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: mark,
      borderRadius: BorderRadius.circular(8),
    ),
    alignment: Alignment.center,
    child: const Text(
      'A',
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Color(0xFF05070C),
      ),
    ),
  );

  Widget _tile(String name, String what, Widget sample) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            color: const Color(0xFF11131A),
            padding: const EdgeInsets.fromLTRB(6, 5, 4, 5),
            height: 47,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFC64D),
                  ),
                ),
                Text(
                  what,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 112,
            child: ClipRect(child: Center(child: sample)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ink,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              color: const Color(0xFF11131A),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: const Text(
                'one AnimationController · CurvedAnimation(easeInOut) · 0 → 1 → 0',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9BD6FF),
                ),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 192 / 163,
                padding: const EdgeInsets.all(6),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  _tile(
                    'ScaleTransition',
                    'scale: Animation<double>',
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.35, end: 1.0).animate(t),
                      child: _box,
                    ),
                  ),
                  _tile(
                    'RotationTransition',
                    'turns: Animation<double>',
                    RotationTransition(
                      turns: Tween<double>(begin: 0.0, end: 0.5).animate(t),
                      child: _box,
                    ),
                  ),
                  _tile(
                    'SlideTransition',
                    'position: Animation<Offset>',
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-1.4, 0),
                        end: const Offset(1.4, 0),
                      ).animate(t),
                      child: _box,
                    ),
                  ),
                  _tile(
                    'FadeTransition',
                    'opacity: Animation<double>',
                    FadeTransition(
                      opacity: Tween<double>(begin: 0.1, end: 1.0).animate(t),
                      child: _box,
                    ),
                  ),
                  _tile(
                    'SizeTransition',
                    'sizeFactor: Animation<double>',
                    SizeTransition(
                      sizeFactor: t,
                      axis: Axis.horizontal,
                      axisAlignment: -1,
                      child: _box,
                    ),
                  ),
                  _tile(
                    'AlignTransition',
                    'alignment: AlignmentTween',
                    SizedBox(
                      width: 170,
                      height: 80,
                      child: AlignTransition(
                        alignment: AlignmentTween(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).animate(t),
                        child: _box,
                      ),
                    ),
                  ),
                  _tile(
                    'DecoratedBoxTransition',
                    'decoration: DecorationTween',
                    DecoratedBoxTransition(
                      decoration: DecorationTween(
                        begin: BoxDecoration(
                          color: mark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        end: BoxDecoration(
                          color: const Color(0xFFFFC64D),
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ).animate(t),
                      child: const SizedBox(width: 56, height: 56),
                    ),
                  ),
                  _tile(
                    'PositionedTransition',
                    'rect: RelativeRectTween (Stack)',
                    SizedBox(
                      width: 170,
                      height: 86,
                      child: Stack(
                        children: <Widget>[
                          PositionedTransition(
                            rect: RelativeRectTween(
                              begin: const RelativeRect.fromLTRB(0, 0, 114, 30),
                              end: const RelativeRect.fromLTRB(114, 30, 0, 0),
                            ).animate(t),
                            child: _box,
                          ),
                        ],
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
