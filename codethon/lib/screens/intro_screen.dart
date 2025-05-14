import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../screens/login_register/auth_screen.dart';
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;

  bool get isNight {
    final hour = DateTime.now().hour;
    return hour >= 20 || hour < 6;
  }

  Color get fondo => isNight ? const Color(0xFF0D1B2A) : const Color(0xFFE6F0FA);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      body: Center(
        child: Lottie.asset(
          'assets/lottie/intro.json',
          controller: _controller,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..forward();
          },
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}
