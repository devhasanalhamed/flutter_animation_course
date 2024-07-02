import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Application',
      theme: ThemeData(brightness: Brightness.dark),
      darkTheme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class LeftCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final Offset offset = Offset(size.width, size.height);
    path.moveTo(size.width, 0);
    path.arcToPoint(
      offset,
      radius: Radius.elliptical(size.width / 2, size.height / 2),
      clockwise: false,
    );
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipPath(
                  clipper: LeftCircleClipper(),
                  child: Container(
                    height: 100,
                    width: 100,
                    color: Colors.amber,
                  ),
                ),
                Container(
                  height: 100,
                  width: 100,
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
