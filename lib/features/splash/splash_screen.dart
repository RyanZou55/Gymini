import 'dart:async';
import 'package:flutter/material.dart';
import '../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 1. Setup Animation (Fade In over 2 seconds)
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Use a curved animation for a smoother look
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // Start the animation
    _controller.forward();

    // 2. Setup Timer to navigate away after 3 seconds
    Timer(const Duration(seconds: 5), () {
      // Check if the widget is still mounted before navigating
      if (mounted) {
        // pushReplacement ensures the user cannot go "back" to the splash screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          // The FadeTransition wraps the content to apply the opacity change
          child: FadeTransition(
            opacity: _animation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- APP LOGO ---
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset(
                    'assets/logo.png', // Uses your square logo
                    height: 150, // Adjust size as needed
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                // --- TAGLINE ---
                const Text(
                  "Gymini, your personal AI gym coach.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic, // Italicized
                    color: Colors.grey, // Grey color
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
