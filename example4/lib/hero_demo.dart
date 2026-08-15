// Capture harness for the vault note on Hero animations.
//
// main.dart is left untouched — this file mirrors it and then varies one thing
// at a time, so each capture isolates a single idea:
//
//   flutter run -t lib/hero_demo.dart --dart-define=VARIANT=hero
//   flutter run -t lib/hero_demo.dart --dart-define=VARIANT=noshuttle
//   flutter run -t lib/hero_demo.dart --dart-define=VARIANT=nohero
//   flutter run -t lib/hero_demo.dart --dart-define=VARIANT=duptag
//
//   hero      - main.dart as written: Hero on both pages + flightShuttleBuilder
//   noshuttle - same, minus flightShuttleBuilder (shows what it is fixing)
//   nohero    - no Hero at all, plain MaterialPageRoute push
//   duptag    - three rows sharing one tag, to trigger the assertion
//
// Every variant runs under timeDilation so a 300 ms transition is legible in a
// recording. The animation itself is unchanged — only the clock is.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

import 'main.dart' show Person, people;

const variant = String.fromEnvironment('VARIANT', defaultValue: 'hero');

void main() {
  timeDilation = 4.0;
  runApp(const HeroDemoApp());
}

class HeroDemoApp extends StatelessWidget {
  const HeroDemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData.dark(useMaterial3: true),
        home: const DemoHomePage(),
      );
}

/// The tag each row hands to its Hero. `duptag` deliberately collides.
String _tagFor(Person person) => variant == 'duptag' ? 'person' : person.name;

/// Wraps [child] in a Hero unless the variant asks for none.
Widget _maybeHero({required Person person, required Widget child}) {
  if (variant == 'nohero') return child;
  return Hero(tag: _tagFor(person), child: child);
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  @override
  void initState() {
    super.initState();
    // The recordings are driven from here, not from injected taps: push the
    // third row, hold, pop, hold, repeat. Every capture is then identical.
    WidgetsBinding.instance.addPostFrameCallback((_) => _drive());
  }

  Future<void> _drive() async {
    // duptag opens the FIRST row on purpose. With every row sharing a tag the
    // map keeps whichever hero was visited last, so the flight starts from the
    // bottom row instead — visible only if the row we opened is not that one.
    final person = variant == 'duptag' ? people.first : people.last;
    while (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DemoDetails(person: person)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1200));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('People'), centerTitle: true),
      body: ListView.builder(
        itemCount: people.length,
        itemBuilder: (context, index) {
          final person = people[index];
          return ListTile(
            leading: _maybeHero(
              person: person,
              child: Text(person.emoji, style: const TextStyle(fontSize: 30.0)),
            ),
            title: Text(person.name),
            subtitle: Text('${person.age} Years old.'),
            trailing: const Icon(Icons.chevron_right, size: 32.0),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DemoDetails(person: person)),
            ),
          );
        },
      ),
    );
  }
}

class DemoDetails extends StatefulWidget {
  const DemoDetails({required this.person, super.key});

  final Person person;

  @override
  State<DemoDetails> createState() => _DemoDetailsState();
}

class _DemoDetailsState extends State<DemoDetails> {
  @override
  void initState() {
    super.initState();
    // Hold long enough for the push flight to land, then fly back.
    Future<void>.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.person;
    const emoji = TextStyle(fontSize: 40.0);

    final Widget title;
    switch (variant) {
      case 'nohero':
        title = Text(person.emoji, style: emoji);
      case 'noshuttle':
        // No flightShuttleBuilder: the default one lifts the destination
        // child into the Navigator overlay, away from this AppBar.
        title = Hero(
          tag: _tagFor(person),
          child: Text(person.emoji, style: emoji),
        );
      default:
        title = Hero(
          tag: _tagFor(person),
          flightShuttleBuilder: (
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
          child: Text(person.emoji, style: emoji),
        );
    }

    return Scaffold(
      appBar: AppBar(title: title, centerTitle: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            person.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32.0),
          ),
          const SizedBox(height: 16.0),
          Text(
            '${person.age} years old',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24.0),
          ),
        ],
      ),
    );
  }
}
