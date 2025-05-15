import 'package:gita_gpt/Utils/app_imports.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? emailErrorText;
  bool isLoading = false;
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
                    listener: (context, state) {
                      if (state is GoogleLoginLoading ||
                          state is FacebookLoginLoading) {
                        setState(() {
                          isLoading = true;
                        });
                      } else if (state is GoogleLoginSuccess) {
                        setState(() {
                          isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green,
                            content: Row(
                              children: [
                                ClipOval(
                                  child: Image.network(
                                    state.image,
                                    height: 20,
                                    width: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Logged in as ${state.name}',
                                  style: FTextStyle.tabbarTextStyle,
                                ),
                              ],
                            ),
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomBottomNavBar(),
                          ),
                        );
                      } else if (state is GoogleLoginFailure) {
                        setState(() {
                          isLoading = false;
                        });
                      } else if (state is FacebookLoginSuccess) {
                        setState(() {
                          isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green,
                            content: Row(
                              children: [
                                ClipOval(
                                  child: Image.network(
                                    state.profileImage,
                                    height: 20,
                                    width: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Logged in as ${state.name}',
                                  style: FTextStyle.tabbarTextStyle,
                                ),
                              ],
                            ),
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomBottomNavBar(),
                          ),
                        );
                      } else if (state is FacebookLoginFailure) {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerRight,
                            child: const LanguageDropdown(),
                          ),
                          const SizedBox(height: 20),
                          Container(
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
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.translate('gitagpt'),
                                    style: FTextStyle.gita_gpt_text,
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
                                    if (emailController.text.isEmpty) {
                                      setState(() {
                                        emailErrorText = AppLocalizations.of(
                                          context,
                                        )!.translate('emptyEmailError');
                                      });
                                    } else if (isValidEmail(
                                      emailController.text,
                                    )) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => CustomBottomNavBar(),
                                        ),
                                      );
                                    }
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
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SignUpScreen(),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.translate('dontHaveAccount'),
                                        style: FTextStyle.defaultText,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.translate('signup'),
                                        style: FTextStyle.defaultTextBold,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {
                                    BlocProvider.of<AuthFlowBloc>(
                                      context,
                                    ).add(GoogleLoginEventHandler());
                                  },
                                  child: Container(
                                    height: 45,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.gradientStart,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/images/google.svg',
                                          height: 24,
                                          width: 24,
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.translate('continueWithGoogle'),
                                          style:
                                              FTextStyle.socialloginbuttonText,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  height: 45,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.gradientStart,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/images/apple-logo.svg',
                                        height: 24,
                                        width: 24,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.translate('continueWithApple'),
                                        style: FTextStyle.socialloginbuttonText,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () {
                                    BlocProvider.of<AuthFlowBloc>(
                                      context,
                                    ).add(FacebookLoginEventHandler());
                                  },
                                  child: Container(
                                    height: 45,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.gradientStart,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/facebook.png',
                                          height: 24,
                                          width: 24,
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.translate('continueWithFacebook'),
                                          style:
                                              FTextStyle.socialloginbuttonText,
                                        ),
                                      ],
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
