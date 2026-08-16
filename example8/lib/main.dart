import 'dart:math';
import 'package:flutter/material.dart';

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

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return MyDrawer(
      drawer: Material(
        child: Container(
          color: const Color(0xFF24283B),
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 80, top: 100),
            itemCount: 20,
            itemBuilder: (context, index) =>
                ListTile(title: Text('Item $index')),
          ),
        ),
      ),
      child: Scaffold(appBar: AppBar(title: Text('3D Drawer'))),
    );
  }
}

class MyDrawer extends StatefulWidget {
  final Widget child;
  final Widget drawer;
  const MyDrawer({super.key, required this.child, required this.drawer});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> with TickerProviderStateMixin {
  late AnimationController xControllerForChild;
  late Animation yRotationAnimationForChild;

  late AnimationController xControllerForDrawer;
  late Animation yRotationAnimationForDrawer;

  @override
  void initState() {
    super.initState();
    xControllerForChild = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    yRotationAnimationForChild = Tween<double>(
      begin: 0.0,
      end: -pi / 2,
    ).animate(xControllerForChild);

    xControllerForDrawer = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    yRotationAnimationForDrawer = Tween<double>(
      begin: pi / 2.7,
      end: 0.0,
    ).animate(xControllerForDrawer);
  }

  @override
  void dispose() {
    super.dispose();
    xControllerForChild.dispose();
    xControllerForDrawer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxDrag = screenWidth * 0.8;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final delta = details.delta.dx / maxDrag;

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
        animation: Listenable.merge([
          xControllerForChild,
          xControllerForDrawer,
        ]),
        builder: (context, child) => Stack(
          children: [
            Container(color: Color(0xFF1A1B26)),
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
                ..rotateY(yRotationAnimationForChild.value),
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
                ..rotateY(yRotationAnimationForDrawer.value),
              child: widget.drawer,
            ),
          ],
        ),
      ),
    );
  }
}
