import 'package:gita_gpt/Screens/splash_screen.dart';
import 'package:gita_gpt/Utils/app_imports.dart';


Future<void> main() async {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return ErrorScreen(errorDetails: details);
  };
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Prefs.init(); // Initialize SharedPreferences
  runApp(
    // Use ChangeNotifierProvider to manage language state
    ChangeNotifierProvider(
      create: (context) => LanguageProvider(),
      child: const MyApp(),
    ),
  );

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => AuthFlowBloc()),
            BlocProvider(create: (context) => HomeFlowBloc()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            supportedLocales: const [
              Locale('hi'), // Hindi
              Locale('en'), // English
            ],
            locale: languageProvider.locale,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            title: 'Gita_GPT',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            ),
            home: LoginScreen(),
          ),
        );
      },
    );
  }
}