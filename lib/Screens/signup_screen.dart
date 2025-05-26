import 'package:gita_gpt/Utils/app_imports.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool nameError = false;
  bool emailError = false;
  bool passwordError = false;
  bool isLoading = false;
  String? nameErrorText;
  String? emailErrorText;
  String? passwordErrorText;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Email validation regex
  bool isValidEmail(String email) {
    return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
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
                    listener: (context, state) async {
                      if (state is GoogleLoginLoading ||
                          state is FacebookLoginLoading ||
                          state is SignUpLoading) {
                        setState(() {
                          isLoading = true;
                        });
                      } else if (state is GoogleLoginSuccess) {
                        final url = state.url;

                        // Try launching the URL
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(
                            Uri.parse(url),
                            mode: LaunchMode.externalApplication, // Opens in browser
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not launch Google login URL')),
                          );
                        }
                      }
                      else if (state is GoogleLoginFailure) {
                        setState(() {
                          isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              'Error : ${state.errorMessage}',
                              style: FTextStyle.tabbarTextStyle,
                            ),
                          ),
                        );
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              'Error : ${state.error}',
                              style: FTextStyle.tabbarTextStyle,
                            ),
                          ),
                        );
                      } else if (state is SignUpSuccess) {
                        PrefUtils.setIsLogin(true);
                        setState(() {
                          isLoading = false;
                        });
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomBottomNavBar(),
                          ),
                        );
                      } else if (state is SignUpFailure) {
                        setState(() {
                          isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              'Error : ${state.failureResponse['message']}',
                              style: FTextStyle.tabbarTextStyle,
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const LanguageDropdown(),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => CustomBottomNavBar(),
                                    ),
                                  );
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Skip',
                                      style: FTextStyle.defaultTextBold,
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.skip_next, size: 18),
                                  ],
                                ),
                              ),
                            ],
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
                            padding: EdgeInsets.all(25),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Center(
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.translate('gitagpt'),
                                    style: FTextStyle.gita_gpt_text,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('dummyText'),
                                  style: FTextStyle.defaultText,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                // Name Field
                                TextFormField(
                                  controller: nameController,
                                  style: FTextStyle.defaultText,
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(
                                      context,
                                    )!.translate('name'),
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
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value.isEmpty) {
                                        nameError = true;
                                        nameErrorText = AppLocalizations.of(
                                          context,
                                        )!.translate('emptyNameError');
                                      } else {
                                        nameError = false;
                                        nameErrorText = null;
                                      }
                                    });
                                  },
                                ),
                                Visibility(
                                  visible: nameError,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 5),
                                      Text(
                                        nameErrorText ?? '',
                                        style: FTextStyle.errorTextStyle,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Email Field
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
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value.isEmpty) {
                                        emailError = true;
                                        emailErrorText = AppLocalizations.of(
                                          context,
                                        )!.translate('emptyEmailError');
                                      } else if (!isValidEmail(value)) {
                                        emailError = true;
                                        emailErrorText = AppLocalizations.of(
                                          context,
                                        )!.translate('invalidEmailError');
                                      } else {
                                        emailError = false;
                                        emailErrorText = null;
                                      }
                                    });
                                  },
                                ),
                                Visibility(
                                  visible: emailError,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 5),
                                      Text(
                                        emailErrorText ?? '',
                                        style: FTextStyle.errorTextStyle,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Password Field
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: true,
                                  style: FTextStyle.defaultText,
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(
                                      context,
                                    )!.translate('password'),
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
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value.isEmpty) {
                                        passwordError = true;
                                        passwordErrorText = AppLocalizations.of(
                                          context,
                                        )!.translate('emptyPasswordError');
                                      } else if (value.length < 6) {
                                        passwordError = true;
                                        passwordErrorText = AppLocalizations.of(
                                          context,
                                        )!.translate('shortPasswordError');
                                      } else {
                                        passwordError = false;
                                        passwordErrorText = null;
                                      }
                                    });
                                  },
                                ),
                                Visibility(
                                  visible: passwordError,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 5),
                                      Text(
                                        passwordErrorText ?? '',
                                        style: FTextStyle.errorTextStyle,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {
                                    bool hasError = false;

                                    if (nameController.text.isEmpty) {
                                      setState(() {
                                        nameError = true;
                                        nameErrorText = AppLocalizations.of(
                                          context,
                                        )!.translate('emptyNameError');
                                      });
                                      hasError = true;
                                    }

                                    if (emailController.text.isEmpty) {
                                      setState(() {
                                        emailError = true;
                                        emailErrorText = AppLocalizations.of(
                                          context,
                                        )!.translate('emptyEmailError');
                                      });
                                      hasError = true;
                                    }

                                    if (passwordController.text.isEmpty) {
                                      setState(() {
                                        passwordError = true;
                                        passwordErrorText = AppLocalizations.of(
                                          context,
                                        )!.translate('emptyPasswordError');
                                      });
                                      hasError = true;
                                    }

                                    if (!hasError) {
                                      // No validation errors, proceed with API call
                                      BlocProvider.of<AuthFlowBloc>(
                                        context,
                                      ).add(
                                        SignupEventHandler(
                                          name: nameController.text.trim(),
                                          email: emailController.text.trim(),
                                          password:
                                              passwordController.text.trim(),
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
                                        )!.translate('signup'),
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
                                        builder: (context) => LoginScreen(),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.translate('alreadyAccount'),
                                        style: FTextStyle.defaultText,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.translate('signin'),
                                        style: FTextStyle.defaultTextBold,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),
                                // Social Login Buttons (Google, Apple, Microsoft)
                                GestureDetector(
                                  onTap: () {
                                    BlocProvider.of<AuthFlowBloc>(context).add(GoogleLoginEventHandler());
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
