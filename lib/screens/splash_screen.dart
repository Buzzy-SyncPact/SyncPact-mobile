import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'landing_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        if (_animationController.isCompleted) {
          navigateToHomeScreen();
        }
      });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void navigateToHomeScreen() {
    Navigator.pushReplacement(
      context,
      // MaterialPageRoute(builder: (context) => const PermissionScreen()),
      MaterialPageRoute(builder: (context) => const LandingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animationController.drive(
                Tween<double>(begin: 0.5, end: 1.0).chain(
                  CurveTween(curve: Curves.easeOutBack),
                ),
              ),
              child: Image.asset(
                'assets/logo.png', // Replace with your logo file path
                height: 700,
                width: 150,
              ),
            ),
            const SizedBox(height: 16),
            FAProgressBar(
              currentValue: 100,
              displayText: '%',
              borderRadius: BorderRadius.circular(5),
              progressColor: Colors.deepPurpleAccent,
              backgroundColor: Colors.black38,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
