import 'package:divine_arc/Utils/app_imports.dart';

class ErrorScreen extends StatefulWidget {
  final FlutterErrorDetails errorDetails; // 👈 add this

  const ErrorScreen({super.key, required this.errorDetails});

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  @override
  Widget build(BuildContext context) {
    final String errorMessage = widget.errorDetails.exceptionAsString();

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bgGitaGPT.png',
                  fit: BoxFit.cover,
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.gradientStart,
                        width: 1.5,
                      ),
                      color: const Color(0xFFFFF3E5),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text('404', style: FTextStyle.divine_arc_text),
                          Image.asset('assets/images/errorImage.png'),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.translate('404heading'),
                            style: FTextStyle.defaultTextBold,
                          ),

                          if (kDebugMode) ...[
                            // 👈 show error only in debug mode
                            const SizedBox(height: 20),
                            Text(
                              errorMessage,
                              textAlign: TextAlign.center,
                              style: FTextStyle.errorTextStyle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          GestureDetector(
                            onTap: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomeScreen(),
                                ),
                                (Route<dynamic> route) => false,
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.gradientStart,
                                    AppColors.gradientEnd,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              height: 45,
                              width: double.infinity,
                              child: Center(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('gotoHomePage'),
                                  style: FTextStyle.buttonText,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
