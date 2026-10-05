import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:divine_arc/APIs/AuthFlow/auth_flow_bloc.dart';
import 'package:divine_arc/Screens/splash_screen.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/notification_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  runZonedGuarded(
    () async {
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return ErrorScreen(errorDetails: details);
      };

      WidgetsFlutterBinding.ensureInitialized();
      // Load environment variables
      await dotenv.load(fileName: ".env");
      // Firebase (splash screen listens on FirebaseMessaging.onMessage immediately)
      // and Prefs (PrefUtils is read synchronously by splash/deep-link handling)
      // both have to be ready before the first frame — everything else below is
      // deferred until after runApp() to get the app on screen as fast as possible,
      // since a cold launch via Universal Link races against iOS's handoff window.
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await Prefs.init();

      runApp(
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
          child: MyApp(),
        ),
      );

      unawaited(FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true));
      unawaited(NotificationService.init());
    },
    (error, stackTrace) {
      debugPrint('Uncaught zone error: $error\n$stackTrace');
    },
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

  // getInitialLink() and the very first uriLinkStream event both fire for the
  // same cold-start URI — this guards against handling it twice.
  Uri? _lastHandledInitialUri;

  // The Universal Link (https) and the fallback page's custom-scheme JS
  // redirect can both deliver for the same tap within a second or two of each
  // other — they arrive as different URIs (different scheme) so raw Uri
  // equality above doesn't catch it. Debounce by the resolved chatId instead,
  // otherwise it opens two GptScreen instances that both complete the same
  // shared bloc's completer, throwing "Bad state: Future already completed".
  String? _lastOpenedChatId;
  DateTime? _lastOpenedChatIdAt;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();

      if (initialUri != null) {
        _lastHandledInitialUri = initialUri;
        _handleDeepLink(initialUri);
      }

      _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
        if (uri == _lastHandledInitialUri) {
          _lastHandledInitialUri = null;
          return;
        }
        _handleDeepLink(uri);
      });
    } catch (e) {
      debugPrint('Deep Link Error: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Deep Link Received: $uri');

    // https://divinearc.in/chat/<id>  -> host: divinearc.in, pathSegments: [chat, id]
    // divinearc://chat/<id>           -> host: chat,         pathSegments: [id]
    // The custom-scheme form puts the route name in the host, not pathSegments —
    // reading pathSegments.first unconditionally misses it.
    final bool isCustomScheme = uri.scheme == 'divinearc';
    final String? route =
        isCustomScheme
            ? uri.host
            : (uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null);
    final List<String> idSegments =
        isCustomScheme
            ? uri.pathSegments
            : (uri.pathSegments.length > 1
                ? uri.pathSegments.sublist(1)
                : const []);

    if (route != 'chat') {
      return;
    }

    final String? chatId = idSegments.isNotEmpty ? idSegments.first : null;

    if (chatId == null) {
      return;
    }

    final now = DateTime.now();
    if (_lastOpenedChatId == chatId &&
        _lastOpenedChatIdAt != null &&
        now.difference(_lastOpenedChatIdAt!) < const Duration(seconds: 5)) {
      debugPrint('Duplicate deep link for chat $chatId ignored');
      return;
    }
    _lastOpenedChatId = chatId;
    _lastOpenedChatIdAt = now;

    _openChat(chatId);
  }

  void _openChat(String chatId) {
    final navigatorState = navigatorKey.currentState;
    if (navigatorState == null) {
      // Navigator not mounted yet — retry once the next frame is up instead of dropping the link.
      WidgetsBinding.instance.addPostFrameCallback((_) => _openChat(chatId));
      return;
    }

    final route = MaterialPageRoute(builder: (_) => GptScreen(chatId: chatId));

    if (navigatorState.canPop()) {
      navigatorState.push(route);
      return;
    }

    final bool isLoggedIn = PrefUtils.getIsLogin();
    final nextScreen =
        isLoggedIn ? const CustomBottomNavBar() : const LoginScreen();

    navigatorState.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => nextScreen),
      (_) => false,
    );

    // pushReplacement's/pushAndRemoveUntil's returned Future only completes when
    // the new route is later popped, not after the transition — so the follow-up
    // push has to be sequenced off a frame callback instead of that Future.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorState.push(route);
    });
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
