import 'package:flutter/material.dart';
import 'dart:math' show pi, cos, sin;

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class Polygon extends CustomPainter {
  final int sides;
  final Color color;

  Polygon({super.repaint, required this.sides, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;
    paint.strokeWidth = 3.0;

    Path path = Path();

    final center = Offset(size.width / 2, size.height / 2);
    final angle = (2 * pi) / sides;
    final radius = size.width / 2;
    final angles = List.generate(sides, (index) => index * angle);

    /*
    x = center.x + radius * cos(angle)
    y = center.y + radius * sin(angle)
    */

    path.moveTo(center.dx + radius * cos(0), center.dy + radius * sin(0));

    for (var angle in angles) {
      path.lineTo(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
    }

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is Polygon && oldDelegate.sides != sides;
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final AnimationController sidesController;
  late final Animation<int> sidesAnimation;

  late final AnimationController radiusController;
  late final Animation<double> radiusAnimation;

  late final AnimationController rotationController;
  late final Animation<double> rotationAnimation;

  @override
  void initState() {
    super.initState();

    sidesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    sidesAnimation = IntTween(begin: 3, end: 10).animate(sidesController);

    radiusController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    radiusAnimation = Tween(
      begin: 20.0,
      end: 200.0,
    ).chain(CurveTween(curve: Curves.bounceInOut)).animate(radiusController);

    rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    rotationAnimation = Tween(
      begin: 0.0,
      end: 2 * pi,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(rotationController);
  }

  @override
  void dispose() {
    sidesController.dispose();
    radiusController.dispose();
    rotationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sidesController.repeat(reverse: true);
    radiusController.repeat(reverse: true);
    rotationController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                sidesController,
                radiusController,
                rotationAnimation,
              ]),
              builder: (context, child) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..rotateX(rotationAnimation.value)
                    ..rotateY(rotationAnimation.value)
                    ..rotateZ(rotationAnimation.value),
                  child: CustomPaint(
                    painter: Polygon(
                      sides: sidesAnimation.value,
                      color: Colors.amber,
                    ),
                    child: SizedBox(
                      width: radiusAnimation.value,
                      height: radiusAnimation.value,
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                sidesController,
                radiusController,
                rotationAnimation,
              ]),
              builder: (context, child) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..rotateZ(rotationAnimation.value),
                  child: CustomPaint(
                    painter: Polygon(
                      sides: sidesAnimation.value,
                      color: Colors.purple,
                    ),
                    child: SizedBox(
                      width: radiusAnimation.value,
                      height: radiusAnimation.value,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
