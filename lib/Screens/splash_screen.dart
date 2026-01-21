import 'dart:async';
import 'dart:developer' as developer;

import 'package:divine_arc/Utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:divine_arc/Screens/customtabbar.dart';
import 'package:divine_arc/Screens/login_screen.dart';
import 'package:divine_arc/Utils/pref_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _splashDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _setupForegroundNotification();
    _initApp();
  }

  Future<void> _initApp() async {
    await _registerFcmToken();
    Timer(_splashDelay, _navigateUser);
  }

  void _setupForegroundNotification() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;

      if (notification != null) {
        NotificationService.showNotification(
          title: notification.title ?? 'Notification',
          body: notification.body ?? '',
        );
      }
    });
  }

  Future<void> _requestNotificationPermission() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    developer.log(
      '🔔 Notification permission: ${settings.authorizationStatus}',
    );
  }

  Future<void> _registerFcmToken() async {
    try {
      await _requestNotificationPermission();

      final token = await FirebaseMessaging.instance.getToken();

      if (token == null || token.isEmpty) {
        developer.log('❌ FCM Token is null or empty');
        return;
      }

      PrefUtils.setDeviceToken(token);

      print('✅ FCM Token: $token');
      print('✅ Stored Device Token: ${PrefUtils.getDeviceToken()}');

      // 🔄 Handle token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        PrefUtils.setDeviceToken(newToken);
        print('🔄 FCM Token refreshed: $newToken');
      });
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error while registering FCM token',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _navigateUser() {
    if (!mounted) return;

    final isLoggedIn = PrefUtils.getIsLogin();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder:
            (_) =>
                isLoggedIn ? const CustomBottomNavBar() : const LoginScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: const Scaffold(
        body: Center(
          child: Image(
            image: AssetImage('assets/images/DivineArcLogo.png'),
            height: 200,
            width: 200,
            fit: BoxFit.cover,
          ),
        ),
      ),
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
