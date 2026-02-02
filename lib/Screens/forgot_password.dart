import 'package:divine_arc/APIs/AuthFlow/auth_flow_bloc.dart';
import 'package:divine_arc/Utils/app_imports.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1)),
        child: Scaffold(
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
                        if (state is ForgotPasswordLoading) {
                          setState(() {
                            isLoading = true;
                          });
                        } else if (state is ForgotPasswordSuccess) {
                          setState(() {
                            isLoading = false;
                          });
                          CommonUtils.showSuccessToast(
                            AppLocalizations.of(
                              context,
                            )!.translate('passwordResetLinkSent'),
                          );
                          Navigator.pop(context);
                        } else if (state is ForgotPasswordFailure) {
                          setState(() {
                            isLoading = false;
                          });
                          CommonUtils.showErrorToast(
                            state.failureResponse['message'],
                          );
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
                        } else if (state is CheckNetworkConnectionAuthFlow) {
                          setState(() {
                            isLoading = false;
                          });
                          CommonUtils.showErrorToast(
                            AppLocalizations.of(
                              context,
                            )!.translate('nointernetConnection'),
                          );
                        } else if (state is CommonServerFailure) {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.black,
                                    size: 22,
                                  ),
                                ),
                                const LanguageDropdown(),
                              ],
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const SizedBox(height: 20),
                                  Center(
                                    child: Image.asset(
                                      'assets/images/DivineArcLogo.png',
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
                                    )!.translate('forgotPassword'),
                                    style: FTextStyle.defaultTextBold.copyWith(
                                      fontSize: 20,
                                    ),
                                  ),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.translate('forgotPasswordsubText'),
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
                                  const SizedBox(height: 10),
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

                                      if (!hasError) {
                                        BlocProvider.of<AuthFlowBloc>(
                                          context,
                                        ).add(
                                          ForgotPasswordEventHandler(
                                            email: emailController.text,
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
                                          )!.translate('submit'),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
