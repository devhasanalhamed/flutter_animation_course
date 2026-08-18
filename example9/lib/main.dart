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
    return Scaffold(
      appBar: AppBar(title: Text('Icons')),
      body: Center(
        child: AnimatedPrompt(
          title: 'Thank you for your order!',
          subTitle: 'Your order will be delivered in 2 days. Enjoy!',
          child: Icon(Icons.check),
        ),
      ),
    );
  }
}

class AnimatedPrompt extends StatefulWidget {
  final String title;
  final String subTitle;
  final Widget child;
  const AnimatedPrompt({
    super.key,
    required this.title,
    required this.subTitle,
    required this.child,
  });

  @override
  State<AnimatedPrompt> createState() => _AnimatedPromptState();
}

class _AnimatedPromptState extends State<AnimatedPrompt>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> iconScaleAnimation;
  late final Animation<double> containerScaleAnimation;
  late final Animation<Offset> yDisplacementAnimation;

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    yDisplacementAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, -0.23),
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    iconScaleAnimation = Tween<double>(
      begin: 7,
      end: 6,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    containerScaleAnimation = Tween<double>(
      begin: 2.0,
      end: 0.4,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.bounceOut));
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    controller
      ..reset()
      ..forward();

    return ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 100,
            minHeight: 100,
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 160.0),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      widget.subTitle,
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
                  position: yDisplacementAnimation,
                  child: ScaleTransition(
                    scale: containerScaleAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                      child: ScaleTransition(
                        scale: iconScaleAnimation,
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
