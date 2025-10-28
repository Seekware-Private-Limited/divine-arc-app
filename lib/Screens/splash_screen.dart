import 'dart:async';
import 'package:flutter/material.dart';
import 'package:divine_arc/Screens/customtabbar.dart';
import 'package:divine_arc/Screens/login_screen.dart';
import 'package:divine_arc/Utils/pref_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () => navigateUser(context));
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        body: Center(
          child: Image.asset(
            'assets/images/DivineArcLogo.png',
            height: 200,
            width: 200,
            fit: BoxFit.cover, // Makes the image fill the screen
          ),
        ),
      ),
    );
  }

  void navigateUser(BuildContext context) {
    // Navigate based on the condition
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (BuildContext context) {
          if (PrefUtils.getIsLogin() == true) {
            return const CustomBottomNavBar();
          } else {
            return const LoginScreen();
          }
        },
      ),
      (route) => false, // Remove all routes from the stack
    );
  }
}

class BackgroundImage extends StatelessWidget {
  final String image;

  const BackgroundImage({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
      ),
    );
  }
}
