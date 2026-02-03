import 'package:divine_arc/APIs/AuthFlow/auth_flow_bloc.dart';
import 'package:divine_arc/Utils/app_imports.dart';

class SignUpScreen extends StatefulWidget {
  final bool isFacebookLoginEnabled;

  const SignUpScreen({super.key, this.isFacebookLoginEnabled = false});

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

  // Name validation regex
  bool isValidName(String name) {
    return RegExp(r"^[A-Za-z ]{1,32}$").hasMatch(name);
  }

  // Email validation regex
  bool isValidEmail(String email) {
    return email.length <= 255 &&
        RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

  // Password validation regex
  bool isValidPassword(String password) {
    return password.length >= 9 &&
        password.length <= 32 &&
        RegExp(
          r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{9,32}$',
        ).hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1)),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bgGitaGPT.png',
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: BlocListener<AuthFlowBloc, AuthFlowState>(
                      listener: (context, state) async {
                        if (state is GoogleLoginLoading ||
                            state is FacebookLoginLoading ||
                            state is SocialLoginLoading ||
                            state is SignUpLoading) {
                          setState(() {
                            isLoading = true;
                          });
                        } else if (state is GoogleLoginSuccess) {
                          setState(() {
                            isLoading = false;
                          });
                          print(state.email);
                          print(state.id);
                          BlocProvider.of<AuthFlowBloc>(context).add(
                            SocialLoginEventHandler(
                              socialId: state.id,
                              socialType: 'google',
                              email: state.email,
                              name: state.name,
                            ),
                          );
                        } else if (state is GoogleLoginFailure) {
                          setState(() {
                            isLoading = false;
                          });
                          CommonUtils.showErrorToast(state.errorMessage);
                        } else if (state is FacebookLoginSuccess) {
                          setState(() {
                            isLoading = false;
                          });
                          CommonUtils.showSuccessToast(
                            'Logged In As - ${state.name}',
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
                          CommonUtils.showErrorToast(state.error);
                        } else if (state is SignUpSuccess) {
                          setState(() {
                            isLoading = false;
                          });
                          PrefUtils.setIsLogin(true);
                          PrefUtils.setIsGuest(false);
                          Navigator.pop(context);
                          CommonUtils.showSuccessToast(
                            'Account Created Successfully!',
                          );
                        } else if (state is SignUpFailure) {
                          setState(() {
                            isLoading = false;
                          });
                          CommonUtils.showErrorToast(
                            state.failureResponse['message'],
                          );
                        } else if (state is SocialLoginSuccess) {
                          setState(() {
                            isLoading = false;
                          });
                          final response = state.successResponse['data'];
                          final name = response['name'];
                          final email = response['email'];
                          PrefUtils.setName(name);
                          PrefUtils.setIsLogin(true);
                          PrefUtils.setEmail(email);
                          PrefUtils.setIsGuest(false);
                          PrefUtils.setIsSocialLogin(true);
                          CommonUtils.showSuccessToast(
                            'Logged in successfully.',
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustomBottomNavBar(),
                            ),
                          );
                        } else if (state is SocialLoginFailure) {
                          setState(() {
                            isLoading = false;
                          });
                          print(state.failureMessage);
                          CommonUtils.showErrorToast(state.failureMessage);
                        } else if (state is SessionExpiredStateAuth) {
                          CommonUtils.showErrorToast(state.message);
                          PrefUtils.clearAll();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
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
                                    PrefUtils.setIsGuest(true);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => CustomBottomNavBar(),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Center(
                                    child: Image.asset(
                                      'assets/images/DivineArcLogo.png',
                                      height: 100,
                                      width: 100,
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
                                        } else if (value.length > 32) {
                                          nameError = true;
                                          nameErrorText = AppLocalizations.of(
                                            context,
                                          )!.translate('nameLengthError');
                                        } else if (!isValidName(value)) {
                                          nameError = true;
                                          nameErrorText = AppLocalizations.of(
                                            context,
                                          )!.translate('invalidNameError');
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
                                    keyboardType: TextInputType.emailAddress,
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
                                        } else if (value.length > 255) {
                                          emailError = true;
                                          emailErrorText = AppLocalizations.of(
                                            context,
                                          )!.translate('emailLengthError');
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
                                          passwordErrorText =
                                              AppLocalizations.of(
                                                context,
                                              )!.translate(
                                                'emptyPasswordError',
                                              );
                                        } else if (value.length < 9) {
                                          passwordError = true;
                                          passwordErrorText =
                                              AppLocalizations.of(
                                                context,
                                              )!.translate(
                                                'shortPasswordError',
                                              );
                                        } else if (value.length > 32) {
                                          passwordError = true;
                                          passwordErrorText =
                                              AppLocalizations.of(
                                                context,
                                              )!.translate('longPasswordError');
                                        } else if (!isValidPassword(value)) {
                                          passwordError = true;
                                          passwordErrorText =
                                              AppLocalizations.of(
                                                context,
                                              )!.translate(
                                                'invalidPasswordError',
                                              );
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
                                      } else if (nameController.text.length >
                                          32) {
                                        setState(() {
                                          nameError = true;
                                          nameErrorText = AppLocalizations.of(
                                            context,
                                          )!.translate('nameLengthError');
                                        });
                                        hasError = true;
                                      } else if (!isValidName(
                                        nameController.text,
                                      )) {
                                        setState(() {
                                          nameError = true;
                                          nameErrorText = AppLocalizations.of(
                                            context,
                                          )!.translate('invalidNameError');
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
                                      } else if (!isValidEmail(
                                        emailController.text,
                                      )) {
                                        setState(() {
                                          emailError = true;
                                          emailErrorText = AppLocalizations.of(
                                            context,
                                          )!.translate('invalidEmailError');
                                        });
                                        hasError = true;
                                      } else if (emailController.text.length >
                                          255) {
                                        setState(() {
                                          emailError = true;
                                          emailErrorText = AppLocalizations.of(
                                            context,
                                          )!.translate('emailLengthError');
                                        });
                                        hasError = true;
                                      }

                                      if (passwordController.text.isEmpty) {
                                        setState(() {
                                          passwordError = true;
                                          passwordErrorText =
                                              AppLocalizations.of(
                                                context,
                                              )!.translate(
                                                'emptyPasswordError',
                                              );
                                        });
                                        hasError = true;
                                      } else if (passwordController
                                              .text
                                              .length <
                                          9) {
                                        setState(() {
                                          passwordError = true;
                                          passwordErrorText =
                                              AppLocalizations.of(
                                                context,
                                              )!.translate(
                                                'shortPasswordError',
                                              );
                                        });
                                        hasError = true;
                                      } else if (passwordController
                                              .text
                                              .length >
                                          32) {
                                        setState(() {
                                          passwordError = true;
                                          passwordErrorText =
                                              AppLocalizations.of(
                                                context,
                                              )!.translate('longPasswordError');
                                        });
                                        hasError = true;
                                      } else if (!isValidPassword(
                                        passwordController.text,
                                      )) {
                                        setState(() {
                                          passwordError = true;
                                          passwordErrorText =
                                              AppLocalizations.of(
                                                context,
                                              )!.translate(
                                                'invalidPasswordError',
                                              );
                                        });
                                        hasError = true;
                                      }

                                      if (!hasError) {
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                                FTextStyle
                                                    .socialloginbuttonText,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Visibility(
                                    visible: widget.isFacebookLoginEnabled,
                                    child: GestureDetector(
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                              )!.translate(
                                                'continueWithFacebook',
                                              ),
                                              style:
                                                  FTextStyle
                                                      .socialloginbuttonText,
                                            ),
                                          ],
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
                                ],
                              ),
                            ),
                          ],
                        ),
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
