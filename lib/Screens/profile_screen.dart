import 'package:divine_arc/Screens/edit_profile.dart';
import 'package:divine_arc/Screens/change_password_screen.dart';
import 'package:divine_arc/Screens/report_issue.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = false;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  String? userName;
  String? userEmail;
  String? profilePictureUrl;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    await _analytics.logEvent(name: 'UserIsOnProfileScreen');

    if (!PrefUtils.getIsGuest()) {
      if (!mounted) return;
      context.read<HomeFlowBloc>().add(ViewUserProfile());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<HomeFlowBloc, HomeFlowState>(
        listener: (context, state) {
          if (state is UserProfileLoading) {
            setState(() => isLoading = true);
          }

          if (state is UserProfileLoaded) {
            final data = state.successResponse['data'];
            setState(() {
              isLoading = false;
              userName = data['name'];
              userEmail = data['email'];
              profilePictureUrl = data['profile_picture'];
            });
          }

          if (state is UserProfileError) {
            setState(() => isLoading = false);
            CommonUtils.showErrorToast(state.failureResponse['message']);
          }

          if (state is LogoutSuccess) {
            _analytics.logEvent(name: 'UserClickedLogout');
            PrefUtils.clearAll();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/bgGitaGPT.png',
                fit: BoxFit.cover,
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('profile'),
                          style: FTextStyle.homeText,
                        ),
                        const LanguageDropdown(),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: Center(
                        child:
                            PrefUtils.getIsGuest()
                                ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ClipOval(
                                      child: Image.asset(
                                        'assets/images/errorImage.png',
                                        height: 250,
                                        width: 250,
                                        fit: BoxFit.cover,
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.translate('guest_title'),
                                      textAlign: TextAlign.center,
                                      style: FTextStyle.defaultTextBold
                                          .copyWith(fontSize: 18),
                                    ),

                                    const SizedBox(height: 8),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.translate('guest_description'),
                                        textAlign: TextAlign.center,
                                        style: FTextStyle.defaultText.copyWith(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 30),

                                    Visibility(
                                      visible: PrefUtils.getIsGuest(),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => LoginScreen(),
                                            ),
                                            (route) => false,
                                          );
                                        },
                                        child: Container(
                                          height: 45,
                                          width: double.infinity,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
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
                                          child: Center(
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.translate('signInToContinue'),
                                              style: FTextStyle.buttonText,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                : Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.gradientStart,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipOval(
                                        child: SizedBox(
                                          height: 160,
                                          width: 160,
                                          child:
                                              profilePictureUrl != null &&
                                                      profilePictureUrl!
                                                          .isNotEmpty
                                                  ? Image.network(
                                                    profilePictureUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) {
                                                      return Image.asset(
                                                        'assets/images/defaultProfile.jpg',
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  )
                                                  : Image.asset(
                                                    'assets/images/defaultProfile.jpg',
                                                    fit: BoxFit.cover,
                                                  ),
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      Text(
                                        userName ?? '',
                                        style: FTextStyle.defaultTextBold,
                                      ),

                                      const SizedBox(height: 6),

                                      Text(
                                        userEmail ?? '',
                                        style: FTextStyle.defaultText,
                                      ),

                                      const SizedBox(height: 30),

                                      if (!PrefUtils.getIsGuest())
                                        ListTile(
                                          leading: Image.asset(
                                            'assets/images/useredit.png',
                                            height: 24,
                                            width: 24,
                                          ),
                                          title: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.translate('editProfile'),
                                            style: FTextStyle.defaultText,
                                          ),
                                          onTap: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => EditProfileScreen(
                                                      name: userName ?? '',
                                                      email: userEmail ?? '',
                                                      profilePictureUrl:
                                                          profilePictureUrl ??
                                                          '',
                                                    ),
                                              ),
                                            );

                                            if (result != null) {
                                              setState(() {
                                                userName = result['name'];
                                                profilePictureUrl =
                                                    result['profile_picture'];
                                              });
                                            }
                                          },
                                        ),

                                      if (!PrefUtils.getIsSocialLogin())
                                        ListTile(
                                          leading: Image.asset(
                                            'assets/images/lock.png',
                                            height: 24,
                                            width: 24,
                                          ),
                                          title: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.translate('updatePassword'),
                                            style: FTextStyle.defaultText,
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
                                                        const ChangePasswordScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                      ListTile(
                                        leading: Image.asset(
                                          'assets/images/feedback.png',
                                          height: 24,
                                          width: 24,
                                        ),
                                        title: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.translate('report_issue_title'),
                                          style: FTextStyle.defaultText,
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
                                                      const ReportIssueScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        leading: Image.asset(
                                          'assets/images/logout.png',
                                          height: 24,
                                          width: 24,
                                        ),
                                        title: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.translate('logout'),
                                          style: FTextStyle.defaultText,
                                        ),
                                        onTap:
                                            () => _showLogoutConfirmation(
                                              context,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.containerBG,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.translate('logout'),
                  style: FTextStyle.defaultTextBold,
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.translate('logout_description'),
                  textAlign: TextAlign.center,
                  style: FTextStyle.defaultText,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          AppLocalizations.of(context)!.translate('cancel'),
                          style: FTextStyle.defaultText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          BlocProvider.of<HomeFlowBloc>(
                            context,
                          ).add(LogoutEvent());
                          Navigator.pop(context);
                        },
                        child: Text(
                          AppLocalizations.of(context)!.translate('logout'),
                          style: FTextStyle.defaultText.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
