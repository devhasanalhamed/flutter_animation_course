import 'package:flutter/material.dart';
import 'package:flutter_animation_course/example_three.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Animation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
      ),
      // home: const ExampleOne(),
      // home: const ExampleTwo(),
      home: const ExampleThree(),
    );
  }
}
