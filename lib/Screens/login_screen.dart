import 'package:gita_gpt/Utils/app_imports.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? emailErrorText;
  final TextEditingController emailController = TextEditingController();

  // Email validation regex
  bool isValidEmail(String email) {
    return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.GlobalBG,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const LanguageDropdown(),
                  const SizedBox(height: 20),
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gradientStart,width: 1.5),
                      color: AppColors.containerBG,
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Center(child: Text(AppLocalizations.of(context)!.translate('gitagpt'),style: FTextStyle.gita_gpt_text)),
                        Text(AppLocalizations.of(context)!.translate('dummyText'),style: FTextStyle.defaultText,textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: emailController,
                          style: FTextStyle.defaultText,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.translate('emailAddress'),
                            hintStyle: FTextStyle.defaultText,
                            filled: true,
                            fillColor: AppColors.GlobalBG,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                                emailErrorText = AppLocalizations.of(context)!.translate('emptyEmailError');
                              } else if (!isValidEmail(value)) {
                                emailErrorText = AppLocalizations.of(context)!.translate('invalidEmailError');
                              } else {
                                emailErrorText = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 5),
                        Visibility(
                          visible: emailErrorText !=null,
                            child: Text(emailErrorText ?? '',style: FTextStyle.errorTextStyle)),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            if(emailController.text.isEmpty){
                              setState(() {
                                emailErrorText = AppLocalizations.of(context)!.translate('emptyEmailError');
                              });
                            }
                            else if(isValidEmail(emailController.text)){
                              Navigator.push(context, MaterialPageRoute(builder: (context) => CustomBottomNavBar()));
                            }
                          },
                          child: Container(
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
                            child: Center(child: Text(AppLocalizations.of(context)!.translate('signin'),style: FTextStyle.buttonText)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignUpScreen()),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(AppLocalizations.of(context)!.translate('dontHaveAccount'),style: FTextStyle.defaultText),
                              const SizedBox(width:5),
                              Text(AppLocalizations.of(context)!.translate('signup'),style: FTextStyle.defaultTextBold),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 45,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.gradientStart,width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset('assets/images/google.svg',height: 24,width: 24),
                              const SizedBox(width: 16),
                              Text(AppLocalizations.of(context)!.translate('continueWithGoogle'),style: FTextStyle.socialloginbuttonText)
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 45,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.gradientStart,width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset('assets/images/apple-logo.svg',height: 24,width: 24),
                              const SizedBox(width: 16),
                              Text(AppLocalizations.of(context)!.translate('continueWithApple'),style: FTextStyle.socialloginbuttonText)
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 45,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.gradientStart,width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset('assets/images/microsoft.svg',height: 24,width: 24),
                              const SizedBox(width: 16),
                              Text(AppLocalizations.of(context)!.translate('continueWithMicrosoft'),style: FTextStyle.socialloginbuttonText)
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (Localizations.localeOf(context).languageCode == 'en') ...[
                              Text(
                                AppLocalizations.of(context)!.translate('poweredBy'),
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
                                AppLocalizations.of(context)!.translate('poweredBy'),
                                style: FTextStyle.defaultText,
                              ),
                            ]
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ),
      ),
    );
  }
}
