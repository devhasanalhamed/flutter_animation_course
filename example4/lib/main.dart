import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

@immutable
class Person {
  final String name;
  final int age;
  final String emoji;

  const Person({required this.name, required this.age, required this.emoji});
}

const people = [
  Person(name: 'John', age: 20, emoji: '🧔🏻‍♂️'),
  Person(name: 'Jane', age: 41, emoji: '👩🏻‍🦳'),
  Person(name: 'Jack', age: 32, emoji: '🧔🏼'),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('People'), centerTitle: true),
      body: ListView.builder(
        itemCount: people.length,
        itemBuilder: (context, index) {
          final person = people[index];
          return ListTile(
            leading: Hero(
              tag: person.name,
              child: Text(person.emoji, style: TextStyle(fontSize: 30.0)),
            ),
            title: Text(person.name),
            subtitle: Text('${person.age} Years old.'),
            trailing: Icon(Icons.chevron_right, size: 32.0),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Details(person: person),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class Details extends StatelessWidget {
  final Person person;
  const Details({required this.person, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: person.name,
          flightShuttleBuilder:
              (
                flightContext,
                animation,
                flightDirection,
                fromHeroContext,
                toHeroContext,
              ) {
                return Material(
                  color: Colors.transparent,
                  child: toHeroContext.widget,
                );
              },
          child: Text(person.emoji, style: TextStyle(fontSize: 40.0)),
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            person.name,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32.0),
          ),
          const SizedBox(height: 16.0),
          Text(
            '${person.age} years old',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24.0),
          ),
        ],
      ),
    );
  }
}
