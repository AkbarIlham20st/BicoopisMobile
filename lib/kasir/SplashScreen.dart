import 'dart:async';
import 'package:flutter/material.dart';
import 'masuk.dart';
import 'package:bicopi_pos/landinglogin.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Setup AnimationController untuk 2 detik
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Animasi dari 0 (kecil & transparan) ke 1 (besar & penuh)
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward(); // mulai animasi

    // Setelah 3 detik pindah ke LoginPage
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SebelumLoginPage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // dispose controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _animation,
            child: Image.asset(
              'assets/Bicopilogo.png',
              width: 200,
              height: 200,
            ),
          ),
        ),
      ),
    );
  }
}
