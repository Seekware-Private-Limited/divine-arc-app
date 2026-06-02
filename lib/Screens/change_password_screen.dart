import 'package:divine_arc/APIs/AuthFlow/auth_flow_bloc.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/session_expired_snackbar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool isLoading = false;
  bool currentpasswordError = false;
  bool newpasswordError = false;
  String? currentpasswordErrorText;
  String? newpasswordErrorText;
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Password validation regex
  bool isValidPassword(String password) {
    return password.length >= 9 &&
        password.length <= 32 &&
        RegExp(
          r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{9,32}$',
        ).hasMatch(password);
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _analytics.logEvent(name: 'UserIsOnChangePasswordScreen');
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
                        if (state is ChangePasswordLoading) {
                          setState(() {
                            isLoading = true;
                          });
                        } else if (state is ChangePasswordSuccess) {
                          setState(() {
                            isLoading = false;
                          });
                          CommonUtils.showSuccessToast(
                            state.successResponse['message'],
                          );
                          Navigator.pop(context);
                        } else if (state is ChangePasswordFailure) {
                          setState(() {
                            isLoading = false;
                          });
                          CommonUtils.showErrorToast(
                            state.failureResponse['message'],
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
                        } else if (state is SessionExpiredStateAuth) {
                          SessionExpiredSnackBar.show(
                            context: context,
                            message: state.message,
                          );
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
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.gradientStart,
                                  width: 1.5,
                                ),
                                color: AppColors.containerBG,
                              ),
                              padding: EdgeInsets.all(16),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    const SizedBox(height: 20),
                                    Center(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
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
                                    const SizedBox(height: 20),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.translate('changePassword'),
                                      style: FTextStyle.defaultTextBold
                                          .copyWith(fontSize: 20),
                                    ),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.translate('changePasswordsubText'),
                                      style: FTextStyle.defaultText,
                                    ),
                                    const SizedBox(height: 30),
                                    TextFormField(
                                      controller: currentPasswordController,
                                      style: FTextStyle.defaultText,
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(
                                          context,
                                        )!.translate('currentPassword'),
                                        hintStyle: FTextStyle.defaultText,
                                        filled: true,
                                        fillColor: AppColors.GlobalBG,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          if (value.isEmpty) {
                                            currentpasswordError = true;
                                            currentpasswordErrorText =
                                                AppLocalizations.of(
                                                  context,
                                                )!.translate(
                                                  'currentPasswordError',
                                                );
                                          } else if (value.length < 9) {
                                            currentpasswordError = true;
                                            currentpasswordErrorText =
                                                AppLocalizations.of(
                                                  context,
                                                )!.translate(
                                                  'currentShortPasswordError',
                                                );
                                          } else if (value.length > 32) {
                                            currentpasswordError = true;
                                            currentpasswordErrorText =
                                                AppLocalizations.of(
                                                  context,
                                                )!.translate(
                                                  'currentLongPasswordError',
                                                );
                                          } else if (!isValidPassword(value)) {
                                            currentpasswordError = true;
                                            currentpasswordErrorText =
                                                AppLocalizations.of(
                                                  context,
                                                )!.translate(
                                                  'currentInvalidPasswordError',
                                                );
                                          } else {
                                            currentpasswordError = false;
                                            currentpasswordErrorText = null;
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 5),
                                    Visibility(
                                      visible: currentpasswordErrorText != null,
                                      child: Text(
                                        currentpasswordErrorText ?? '',
                                        style: FTextStyle.errorTextStyle,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: newPasswordController,
                                      style: FTextStyle.defaultText,
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(
                                          context,
                                        )!.translate('newPassword'),
                                        hintStyle: FTextStyle.defaultText,
                                        filled: true,
                                        fillColor: AppColors.GlobalBG,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          if (value.isEmpty) {
                                            newpasswordError = true;
                                            newpasswordErrorText =
                                                AppLocalizations.of(
                                                  context,
                                                )!.translate(
                                                  'newPasswordError',
                                                );
                                          } else if (value.length < 9) {
                                            newpasswordError = true;
                                            newpasswordErrorText =
                                                AppLocalizations.of(
                                                  context,
                                                )!.translate(
                                                  'newShortPasswordError',
                                                );
                                          } else if (value.length > 32) {
                                            newpasswordError = true;
                                            newpasswordErrorText =
                                                AppLocalizations.of(
                                                  context,
                                                )!.translate(
                                                  'newLongPasswordError',
                                                );
                                          } else if (!isValidPassword(value)) {
                                            newpasswordError = true;
                                            newpasswordErrorText =
                                                AppLocalizations.of(
                                                  context,
                                                )!.translate(
                                                  'newInvalidPasswordError',
                                                );
                                          } else {
                                            newpasswordError = false;
                                            newpasswordErrorText = null;
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 5),
                                    Visibility(
                                      visible: newpasswordErrorText != null,
                                      child: Text(
                                        newpasswordErrorText ?? '',
                                        style: FTextStyle.errorTextStyle,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: () {
                                        bool hasError = false;

                                        if (currentPasswordController
                                            .text
                                            .isEmpty) {
                                          setState(() {
                                            currentpasswordErrorText =
                                                AppLocalizations.of(
                                                  context,
                                                )!.translate(
                                                  'currentPasswordError',
                                                );
                                          });
                                          hasError = true;
                                        }
                                        if (newPasswordController
                                            .text
                                            .isEmpty) {
                                          setState(() {
                                            newpasswordErrorText =
                                                AppLocalizations.of(
                                                  context,
                                                )!.translate(
                                                  'newPasswordError',
                                                );
                                          });
                                          hasError = true;
                                        } else if (!isValidPassword(
                                          currentPasswordController.text,
                                        )) {
                                          setState(() {
                                            currentpasswordErrorText =
                                                AppLocalizations.of(
                                                  context,
                                                )!.translate(
                                                  'currentInvalidPasswordError',
                                                );
                                          });
                                          hasError = true;
                                        } else if (!isValidPassword(
                                          newPasswordController.text,
                                        )) {
                                          setState(() {
                                            newpasswordErrorText =
                                                AppLocalizations.of(
                                                  context,
                                                )!.translate(
                                                  'newInvalidPasswordError',
                                                );
                                          });
                                          hasError = true;
                                        }

                                        if (!hasError) {
                                          BlocProvider.of<AuthFlowBloc>(
                                            context,
                                          ).add(
                                            ChangePasswordEventHandler(
                                              currentPassword:
                                                  currentPasswordController
                                                      .text,
                                              newPassword:
                                                  newPasswordController.text,
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
