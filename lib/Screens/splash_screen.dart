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

  VideoPlayerController? _videoController;
  bool _hasNavigated = false;
  Timer? _splashSafetyTimer;

  @override
  void initState() {
    super.initState();

    _setupForegroundNotification();
    _initVideoAndApp();

    // Absolute safety net: navigation must never depend solely on the video
    // subsystem succeeding. If video init/playback hangs or throws on a
    // device/OS combo we haven't seen, this guarantees the app still moves
    // past the splash screen instead of sitting frozen (which App Store
    // review — rightly — treats as indistinguishable from a crash).
    _splashSafetyTimer = Timer(const Duration(seconds: 8), () {
      if (!_hasNavigated) {
        _hasNavigated = true;
        _navigateUser();
      }
    });
  }

  Future<void> _initVideoAndApp() async {
    try {
      final controller = VideoPlayerController.asset(
        'assets/videos/splash_video.mp4',
      );
      _videoController = controller;

      await controller.initialize().timeout(const Duration(seconds: 4));

      controller.setLooping(false);

      controller.addListener(() {
        if (controller.value.isInitialized &&
            controller.value.position >= controller.value.duration &&
            !_hasNavigated) {
          _hasNavigated = true;
          _navigateUser();
        }
      });

      if (mounted) {
        setState(() {});
      }

      unawaited(controller.play());
    } catch (e, stackTrace) {
      debugPrint('Splash video failed to init or play: $e\n$stackTrace');
      if (!_hasNavigated) {
        _hasNavigated = true;
        _navigateUser();
      }
    }

    try {
      await upgrader.initialize();
    } catch (e) {
      debugPrint('Upgrader init failed: $e');
    }
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

    if (Navigator.of(context).canPop()) {
      debugPrint(
        'Skipping splash navigation because a deep link or another route is already active.',
      );
      return;
    }

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
    _splashSafetyTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _videoController;

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        backgroundColor: Colors.black,
        body:
            controller != null && controller.value.isInitialized
                ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  ),
                )
                : const SizedBox.shrink(),
      ),
    );
  }
}
