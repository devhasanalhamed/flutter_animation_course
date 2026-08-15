import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

const double defaultWidth = 200;
const Curve defaultCurve = Curves.bounceIn;

class _HomePageState extends State<HomePage> {
  var isZoomedIn = false;
  var width = defaultWidth;
  var curve = defaultCurve;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Homepage')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16.0,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 370),
                width: width,
                curve: curve,
                child: Image.asset('assets/images/city.jpg'),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              setState(() {
                isZoomedIn = !isZoomedIn;
                width = isZoomedIn
                    ? MediaQuery.of(context).size.width
                    : defaultWidth;
                curve = isZoomedIn ? Curves.bounceOut : Curves.decelerate;
              });
            },
            child: Text(isZoomedIn ? 'Zoom Out' : 'Zoom In'),
          ),
        ],
      ),
    );
  }
}
