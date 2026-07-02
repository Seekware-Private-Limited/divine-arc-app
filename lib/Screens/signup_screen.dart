import 'package:divine_arc/APIs/AuthFlow/auth_flow_bloc.dart';
import 'package:divine_arc/Screens/privacy_policy.dart';
import 'package:divine_arc/Screens/terms_conditions.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/session_expired_snackbar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class SignUpScreen extends StatefulWidget {
  final bool isFacebookLoginEnabled;
  final bool isGoogleLoginEnabled;
  const SignUpScreen({
    super.key,
    this.isFacebookLoginEnabled = false,
    this.isGoogleLoginEnabled = false,
  });

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
  String? selectedGender;
  String? backendFormattedDob;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController placeofbirthController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    dobController.dispose();
    placeofbirthController.dispose();
    genderController.dispose();
    super.dispose();
  }

  bool isValidName(String name) {
    return RegExp(r"^[A-Za-z ]{1,32}$").hasMatch(name);
  }

  bool isValidEmail(String email) {
    return email.length <= 255 &&
        RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

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
          resizeToAvoidBottomInset: true,
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
                          CommonUtils.showErrorToast(state.failureMessage);
                        } else if (state is SessionExpiredStateAuth) {
                          SessionExpiredSnackBar.show(
                            context: context,
                            message: state.message,
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
                                  onTap: () async {
                                    await _analytics.logEvent(
                                      name: 'SkipButtonTapped',
                                    );
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
                                        AppLocalizations.of(
                                          context,
                                        )!.translate('skip'),
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
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(100),
                                      child: Image.asset(
                                        'assets/images/DivineArcLogo.png',
                                        height: 100,
                                        width: 100,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.translate('dummyText'),
                                    style: FTextStyle.defaultText,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
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
                                  TextFormField(
                                    controller: passwordController,
                                    style: FTextStyle.defaultText,
                                    obscureText: true,
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
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.GlobalBG,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedGender,
                                        isExpanded: true,
                                        dropdownColor: AppColors.GlobalBG,
                                        hint: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.translate('gender'),
                                          style: FTextStyle.defaultText
                                              .copyWith(color: Colors.black),
                                        ),
                                        icon: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: AppColors.gradientStart,
                                        ),
                                        style: FTextStyle.defaultText,
                                        items: [
                                          DropdownMenuItem(
                                            value: 'Male',
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.translate('male'),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Female',
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.translate('female'),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Other',
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.translate('other'),
                                            ),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            selectedGender = value;
                                            genderController.text =
                                                value != null
                                                    ? value.toLowerCase()
                                                    : '';
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: dobController,
                                    readOnly: true,
                                    style: FTextStyle.defaultText,
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(
                                        context,
                                      )!.translate('date_of_birth'),
                                      hintStyle: FTextStyle.defaultText,
                                      filled: true,
                                      fillColor: AppColors.GlobalBG,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 14,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      suffixIcon: Icon(
                                        Icons.calendar_month_rounded,
                                        color: AppColors.gradientStart,
                                      ),
                                    ),
                                    onTap: () async {
                                      FocusScope.of(context).unfocus();
                                      final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime.now(),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme:
                                                  const ColorScheme.light(
                                                    primary:
                                                        AppColors.gradientStart,
                                                    onPrimary: Colors.white,
                                                    surface:
                                                        AppColors.containerBG,
                                                    onSurface: Colors.black,
                                                  ),
                                              scaffoldBackgroundColor:
                                                  AppColors.containerBG,
                                              dialogBackgroundColor:
                                                  AppColors.containerBG,
                                              textTheme: Theme.of(
                                                context,
                                              ).textTheme.copyWith(
                                                headlineLarge:
                                                    FTextStyle
                                                        .defaultTextSemiBold,
                                                headlineMedium:
                                                    FTextStyle
                                                        .defaultTextSemiBold,
                                                titleLarge:
                                                    FTextStyle
                                                        .defaultTextSemiBold,
                                                bodyLarge:
                                                    FTextStyle.defaultText,
                                                bodyMedium:
                                                    FTextStyle.defaultText,
                                                labelLarge:
                                                    FTextStyle.defaultTextBold,
                                              ),
                                              textButtonTheme:
                                                  TextButtonThemeData(
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          AppColors
                                                              .gradientStart,
                                                      textStyle:
                                                          FTextStyle
                                                              .defaultTextBold,
                                                    ),
                                                  ),
                                              datePickerTheme: DatePickerThemeData(
                                                backgroundColor:
                                                    AppColors.containerBG,
                                                headerBackgroundColor:
                                                    AppColors.gradientStart,
                                                headerForegroundColor:
                                                    Colors.white,
                                                dayStyle:
                                                    FTextStyle.defaultText,
                                                yearStyle:
                                                    FTextStyle.defaultText,
                                                todayForegroundColor:
                                                    WidgetStateProperty.all(
                                                      Colors.black,
                                                    ),
                                                todayBorder: BorderSide(
                                                  color: Colors.black,
                                                  width: 1.5,
                                                ),
                                                confirmButtonStyle:
                                                    TextButton.styleFrom(
                                                      foregroundColor:
                                                          AppColors
                                                              .gradientStart,
                                                      textStyle:
                                                          FTextStyle
                                                              .defaultTextBold,
                                                    ),
                                                cancelButtonStyle:
                                                    TextButton.styleFrom(
                                                      foregroundColor:
                                                          AppColors
                                                              .gradientStart,
                                                      textStyle:
                                                          FTextStyle
                                                              .defaultTextBold,
                                                    ),
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );

                                      if (pickedDate != null) {
                                        setState(() {
                                          dobController.text =
                                              "${pickedDate.day.toString().padLeft(2, '0')}/"
                                              "${pickedDate.month.toString().padLeft(2, '0')}/"
                                              "${pickedDate.year}";
                                          backendFormattedDob =
                                              "${pickedDate.year}-"
                                              "${pickedDate.month.toString().padLeft(2, '0')}-"
                                              "${pickedDate.day.toString().padLeft(2, '0')}";
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: placeofbirthController,
                                    style: FTextStyle.defaultText,
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(
                                        context,
                                      )!.translate('place_of_birth'),
                                      hintStyle: FTextStyle.defaultText,
                                      filled: true,
                                      fillColor: AppColors.GlobalBG,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 14,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: () async {
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
                                        await _analytics.logEvent(
                                          name: 'SignUpButtonClicked',
                                          parameters: {
                                            'name': nameController.text.trim(),
                                            'email':
                                                emailController.text.trim(),
                                            'password':
                                                passwordController.text.trim(),
                                          },
                                        );
                                        BlocProvider.of<AuthFlowBloc>(
                                          context,
                                        ).add(
                                          SignupEventHandler(
                                            name: nameController.text.trim(),
                                            email: emailController.text.trim(),
                                            password:
                                                passwordController.text.trim(),
                                            gender:
                                                genderController.text.trim(),
                                            dateOfBirth:
                                                (backendFormattedDob ??
                                                        dobController.text)
                                                    .trim(),
                                            placeOfBirth:
                                                placeofbirthController.text
                                                    .trim(),
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
                                  const SizedBox(height: 24),
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: FTextStyle.rateNowBlack,
                                      children: [
                                        const TextSpan(
                                          text:
                                              'By continuing, you agree to our ',
                                        ),
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) =>
                                                          const TermsConditionsScreen(),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              'Terms & Conditions',
                                              style: FTextStyle.rateNowBlack
                                                  .copyWith(
                                                    color:
                                                        AppColors.gradientStart,
                                                    decoration:
                                                        TextDecoration
                                                            .underline,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const TextSpan(text: ' and '),
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) =>
                                                          const PrivacyPolicyScreen(),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              'Privacy Policy',
                                              style: FTextStyle.rateNowBlack
                                                  .copyWith(
                                                    color:
                                                        AppColors.gradientStart,
                                                    decoration:
                                                        TextDecoration
                                                            .underline,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const TextSpan(text: '.'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Visibility(
                                    visible: widget.isGoogleLoginEnabled,
                                    child: GestureDetector(
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                              )!.translate(
                                                'continueWithGoogle',
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
