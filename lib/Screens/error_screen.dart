import '../Utils/app_imports.dart';
import 'package:flutter/foundation.dart'; // 👈 for kDebugMode

class ErrorScreen extends StatefulWidget {
  final FlutterErrorDetails errorDetails; // 👈 add this

  const ErrorScreen({super.key, required this.errorDetails});

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  @override
  Widget build(BuildContext context) {
    final String errorMessage = widget.errorDetails.exceptionAsString(); // get the error

    return Scaffold(
      backgroundColor: AppColors.GlobalBG,
      body: SafeArea(
        child: Center(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('404', style: FTextStyle.gita_gpt_text),
                  Image.asset('assets/images/errorImage.png'),
                  Text('OOPS 404 ERROR OCCURED!', style: FTextStyle.defaultTextBold),

                  if (kDebugMode) ...[  // 👈 show error only in debug mode
                    const SizedBox(height: 20),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: FTextStyle.errorTextStyle.copyWith(fontSize: 16,fontWeight: FontWeight.w900)
                    ),
                  ],

                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.gradientStart, AppColors.gradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    height: 45,
                    width: double.infinity,
                    child: Center(child: Text('Go to Home Page', style: FTextStyle.buttonText)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
