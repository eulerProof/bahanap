import 'package:cc206_bahanap/features/get_started.dart';
import 'package:cc206_bahanap/features/sign_in_page.dart';
import 'package:flutter/material.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const GetStarted(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    });

    return const Scaffold(
      backgroundColor: Color(0xFF32ade6),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(21),
            child: Text(
              'BaHanap',
              style: TextStyle(
                fontSize: 70,
                fontFamily: 'Gilroy',
                color: Colors.white,
                letterSpacing: -6.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
