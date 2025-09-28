import 'package:gita_gpt/Utils/app_imports.dart';

class OtpVerificationPasswordScreen extends StatefulWidget {
  const OtpVerificationPasswordScreen({super.key});

  @override
  State<OtpVerificationPasswordScreen> createState() =>
      _OtpVerificationPasswordScreenState();
}

class _OtpVerificationPasswordScreenState
    extends State<OtpVerificationPasswordScreen> {
  String? emailErrorText;
  bool isLoading = false;
  final TextEditingController emailController = TextEditingController();

  // Email validation regex
  bool isValidEmail(String email) {
    return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
                child: SingleChildScrollView(
                  child: BlocListener<AuthFlowBloc, AuthFlowState>(
                    listener: (context, state) async {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: const LanguageDropdown(),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: screenHeight * 0.70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.gradientStart,
                                width: 1.5,
                              ),
                              color: AppColors.containerBG,
                            ),
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(height: 20),
                                Center(
                                  child: Image.asset(
                                    'assets/images/GitaGPTLogo.png',
                                    height: 100,
                                    width: 100,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('dummyText'),
                                  style: FTextStyle.defaultText,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('otpVerification'),
                                  style: FTextStyle.defaultTextBold.copyWith(
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('otpVerifcationsubText'),
                                  style: FTextStyle.defaultText,
                                ),
                                const SizedBox(height: 30),
                                TextFormField(
                                  controller: emailController,
                                  style: FTextStyle.defaultText,
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(
                                      context,
                                    )!.translate('emailAddress'),
                                    hintStyle: FTextStyle.defaultText,
                                    filled: true,
                                    fillColor: AppColors.GlobalBG,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value.isEmpty) {
                                        emailErrorText = AppLocalizations.of(
                                          context,
                                        )!.translate('emptyEmailError');
                                      } else if (!isValidEmail(value)) {
                                        emailErrorText = AppLocalizations.of(
                                          context,
                                        )!.translate('invalidEmailError');
                                      } else {
                                        emailErrorText = null;
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: 5),
                                Visibility(
                                  visible: emailErrorText != null,
                                  child: Text(
                                    emailErrorText ?? '',
                                    style: FTextStyle.errorTextStyle,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {
                                    bool hasError = false;

                                    if (emailController.text.isEmpty) {
                                      setState(() {
                                        emailErrorText = AppLocalizations.of(
                                          context,
                                        )!.translate('emptyEmailError');
                                      });
                                      hasError = true;
                                    } else if (!isValidEmail(
                                      emailController.text,
                                    )) {
                                      setState(() {
                                        emailErrorText = AppLocalizations.of(
                                          context,
                                        )!.translate('invalidEmailError');
                                      });
                                      hasError = true;
                                    }

                                    if (!hasError) {}
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
                                        )!.translate('signin'),
                                        style: FTextStyle.buttonText,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (Localizations.localeOf(
                                          context,
                                        ).languageCode ==
                                        'en') ...[
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.translate('poweredBy'),
                                        style: FTextStyle.defaultText,
                                      ),
                                      const SizedBox(width: 5),
                                      SvgPicture.asset(
                                        'assets/images/vex.svg',
                                        height: 16,
                                        width: 16,
                                      ),
                                    ] else ...[
                                      SvgPicture.asset(
                                        'assets/images/vex.svg',
                                        height: 16,
                                        width: 16,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.translate('poweredBy'),
                                        style: FTextStyle.defaultText,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      color: AppColors.gradientStart,
                      size: 50,
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
