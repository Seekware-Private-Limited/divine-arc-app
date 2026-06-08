import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:divine_arc/APIs/AuthFlow/auth_flow_bloc.dart';
import 'package:divine_arc/Screens/splash_screen.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/notification_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return ErrorScreen(errorDetails: details);
  };

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  await Prefs.init();

  await NotificationService.init();

  runApp(
    ChangeNotifierProvider(create: (_) => LanguageProvider(), child: MyApp()),
  );
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();

      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }

      _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
        _handleDeepLink(uri);
      });
    } catch (e) {
      debugPrint('Deep Link Error: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Deep Link Received: $uri');

    if (uri.pathSegments.isEmpty) {
      return;
    }

    if (uri.pathSegments.first == 'chat') {
      final String? chatId =
          uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;

      if (chatId == null) {
        return;
      }

      final navigatorState = navigatorKey.currentState;
      if (navigatorState == null) return;

      final route = MaterialPageRoute(
        builder: (_) => GptScreen(chatId: chatId),
      );

      if (navigatorState.canPop()) {
        navigatorState.push(route);
      } else {
        final bool isLoggedIn = PrefUtils.getIsLogin();
        final nextScreen =
            isLoggedIn ? const CustomBottomNavBar() : const LoginScreen();

        navigatorState
            .pushReplacement(MaterialPageRoute(builder: (_) => nextScreen))
            .then((_) {
              navigatorState.push(route);
            });
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => AuthFlowBloc()),
            BlocProvider(create: (_) => HomeFlowBloc()),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [
              FirebaseAnalyticsObserver(analytics: analytics),
            ],
            debugShowCheckedModeBanner: false,
            title: 'Divine ARC',
            supportedLocales: const [Locale('hi'), Locale('en')],
            locale: languageProvider.locale,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
