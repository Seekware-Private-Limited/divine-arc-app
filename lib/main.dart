import 'package:divine_arc/APIs/AuthFlow/auth_flow_bloc.dart';
import 'package:divine_arc/Screens/splash_screen.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/notification_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:upgrader/upgrader.dart';
import 'firebase_options.dart';

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

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

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
