import 'dart:async';
import 'dart:developer' as developer;

import 'package:divine_arc/APIs/AuthFlow/auth_flow_bloc.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:upgrader/upgrader.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final Upgrader upgrader = Upgrader();

  late VideoPlayerController _videoController;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _setupForegroundNotification();
    _initVideoAndApp();
  }

  Future<void> _initVideoAndApp() async {
    _videoController = VideoPlayerController.asset(
      'assets/videos/splash_video.mp4',
    );

    await _videoController.initialize();

    _videoController.setLooping(false);

    _videoController.addListener(() {
      if (_videoController.value.isInitialized &&
          _videoController.value.position >= _videoController.value.duration &&
          !_hasNavigated) {
        _hasNavigated = true;
        _navigateUser();
      }
    });

    if (mounted) {
      setState(() {});
    }

    _videoController.play();

    await upgrader.initialize();
    await _registerFcmToken();
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

      developer.log('✅ FCM Token: $token');

      if (!mounted) return;

      BlocProvider.of<AuthFlowBloc>(context).add(
        SendDeviceTokenEvent(deviceToken: token, userID: PrefUtils.getID()),
      );

      developer.log('✅ Stored Device Token: ${PrefUtils.getDeviceToken()}');

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        PrefUtils.setDeviceToken(newToken);

        developer.log('🔄 FCM Token refreshed: $newToken');
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

    final nextScreen =
        isLoggedIn ? const CustomBottomNavBar() : const LoginScreen();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => nextScreen),
      (_) => false,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (upgrader.shouldDisplayUpgrade()) {
        _showCustomUpdateDialog();
      }
    });
  }

  void _showCustomUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: AppColors.containerBG,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/DivineArcLogo.png', height: 80),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.translate('update_available'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  upgrader.body(upgrader.determineMessages(context)),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    if (!upgrader.blocked())
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: Text(
                            AppLocalizations.of(context)!.translate('later'),
                          ),
                        ),
                      ),
                    if (!upgrader.blocked()) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          upgrader.sendUserToAppStore();
                        },
                        child: Text(
                          AppLocalizations.of(context)!.translate('update'),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!upgrader.blocked())
                  TextButton(
                    onPressed: () {
                      upgrader.saveIgnored();
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text(
                      AppLocalizations.of(context)!.translate('nothanks'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        backgroundColor: Colors.black,
        body:
            _videoController.value.isInitialized
                ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                )
                : const SizedBox.shrink(),
      ),
    );
  }
}
