import 'package:divine_arc/APIs/HomeFlow/home_flow_bloc.dart';
import 'package:divine_arc/Screens/change_password_screen.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/common_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool nameError = false;
  bool emailError = false;
  bool passwordError = false;
  String? nameErrorText;
  String? emailErrorText;
  String? passwordErrorText;
  bool isLoading = false;
  bool isEdit = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Email validation regex
  bool isValidEmail(String email) {
    return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

  @override
  void initState() {
    super.initState();
    nameController.text = PrefUtils.getName();
    emailController.text = PrefUtils.getEmail();
  }

  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Container(
            padding: EdgeInsets.all(20),
            height: 160,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text(
                    'Take From Camera',
                    style: FTextStyle.defaultText,
                  ),
                  onTap: () async {
                    Navigator.pop(context); // close bottom sheet
                    final pickedFile = await _picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (pickedFile != null) {
                      setState(() => _image = pickedFile);
                      await PrefUtils.setProfilePicture(pickedFile.path);
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo),
                  title: Text(
                    'Take From Gallery',
                    style: FTextStyle.defaultText,
                  ),
                  onTap: () async {
                    Navigator.pop(context); // close bottom sheet
                    final pickedFile = await _picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (pickedFile != null) {
                      setState(() => _image = pickedFile);
                      await PrefUtils.setProfilePicture(pickedFile.path);
                    }
                  },
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
                const Text("Logout", style: FTextStyle.defaultTextBold),
                const SizedBox(height: 12),
                const Text(
                  "Are you sure you want to logout?",
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
                        child: const Text(
                          "Cancel",
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
                          "Logout",
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

  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        body: BlocListener<HomeFlowBloc, HomeFlowState>(
          listener: (context, state) {
            if (state is LogoutLoading) {
              setState(() {
                isLoading = true;
              });
            } else if (state is LogoutSuccess) {
              setState(() {
                isLoading = false;
              });
              PrefUtils.clearAll();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
              CommonUtils.showSuccessToast("Logged out successfully!");
            } else if (state is LogoutFailure) {
              setState(() {
                isLoading = false;
              });
              CommonUtils.showErrorToast(state.failureResponse['message']);
            } else if (state is UpdateProfileLoading) {
              setState(() {
                isLoading = true;
              });
            } else if (state is UpdateProfileLoaded) {
              setState(() {
                isLoading = false;
              });
              isEdit = false;
              final response = state.successResponse;
              final name = response['data']['name'];
              PrefUtils.setName(name);
              CommonUtils.showSuccessToast('Profile Updated Successfully!');
            } else if (state is UpdateProfileError) {
              setState(() {
                isLoading = false;
              });
              CommonUtils.showErrorToast(state.failureResponse['message']);
            }
          },
          child: Stack(
            children: [
              // Background image covers entire screen
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bgGitaGPT.png',
                  fit: BoxFit.cover,
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 32,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.translate('profile'),
                              style: FTextStyle.homeText,
                            ),
                            const LanguageDropdown(),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: screenHeight * 0.68,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.gradientStart,
                              width: 1.5,
                            ),
                            color: Colors.white,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  PrefUtils.getIsGuest()
                                      ? MainAxisAlignment.spaceEvenly
                                      : MainAxisAlignment.center,
                              children: [
                                if (!PrefUtils.getIsGuest())
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isEdit = !isEdit;
                                        });
                                      },
                                      child:
                                          isEdit
                                              ? Image.asset(
                                                'assets/images/close.png',
                                                height: 15,
                                                width: 15,
                                              )
                                              : Image.asset(
                                                'assets/images/edit.png',
                                                height: 24,
                                                width: 24,
                                              ),
                                    ),
                                  ),
                                Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ClipOval(
                                        child: SizedBox(
                                          height: 120,
                                          width: 120,
                                          child:
                                              _image != null
                                                  ? Image.file(
                                                    File(_image!.path),
                                                    fit: BoxFit.cover,
                                                  )
                                                  : (PrefUtils.getProfilePicture()
                                                          .isNotEmpty &&
                                                      File(
                                                        PrefUtils.getProfilePicture(),
                                                      ).existsSync())
                                                  ? Image.file(
                                                    File(
                                                      PrefUtils.getProfilePicture(),
                                                    ),
                                                    fit: BoxFit.cover,
                                                  )
                                                  : Image.asset(
                                                    'assets/images/defaultProfile.jpg',
                                                    fit: BoxFit.cover,
                                                  ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap:
                                              () => _showImageSourceActionSheet(
                                                context,
                                              ),
                                          child: Container(
                                            padding: EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              border: Border.all(
                                                color: Colors.grey,
                                              ),
                                            ),
                                            child: Image.asset(
                                              'assets/images/photo-camera.png',
                                              height: 18,
                                              width: 18,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                PrefUtils.getIsGuest()
                                    ? Column(
                                      children: [
                                        const SizedBox(height: 20),
                                        Center(
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.translate('guestDescription'),
                                            style:
                                                FTextStyle
                                                    .socialloginbuttonText,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    )
                                    : Column(
                                      children: [
                                        const SizedBox(height: 10),
                                        Center(
                                          child: Text(
                                            PrefUtils.getName(),
                                            style: FTextStyle.defaultText,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Center(
                                          child: Text(
                                            PrefUtils.getEmail(),
                                            style: FTextStyle.defaultText,
                                          ),
                                        ),
                                      ],
                                    ),

                                const SizedBox(height: 30),

                                // Name Field
                                Visibility(
                                  visible: !PrefUtils.getIsGuest(),
                                  child: TextFormField(
                                    controller: nameController,
                                    readOnly: isEdit ? false : true,
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
                                Visibility(
                                  visible: !PrefUtils.getIsGuest(),
                                  child: TextFormField(
                                    controller: emailController,
                                    readOnly: true,
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

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),

                                    // Update Password Button
                                    Visibility(
                                      visible:
                                          isEdit &&
                                          !PrefUtils.getIsSocialLogin(),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            isEdit = false;
                                          });
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      ChangePasswordScreen(),
                                            ),
                                          );
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
                                              )!.translate('updatePassword'),
                                              style: FTextStyle.buttonText,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),
                                    // Save Button
                                    Visibility(
                                      visible: isEdit,
                                      child: GestureDetector(
                                        onTap: () async {
                                          // Reset errors
                                          setState(() {
                                            nameError = false;
                                            emailError = false;
                                            passwordError = false;
                                          });

                                          bool isValid = true;

                                          if (nameController.text.isEmpty) {
                                            setState(() {
                                              nameError = true;
                                              nameErrorText =
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.translate(
                                                    'emptyNameError',
                                                  );
                                            });
                                            isValid = false;
                                          }

                                          if (emailController.text.isEmpty) {
                                            setState(() {
                                              emailError = true;
                                              emailErrorText =
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.translate(
                                                    'emptyEmailError',
                                                  );
                                            });
                                            isValid = false;
                                          }
                                          if (isValid) {
                                            // Optional: Show loading indicator or disable button

                                            // 🔁 Call your update profile API here
                                            BlocProvider.of<HomeFlowBloc>(
                                              context,
                                            ).add(
                                              UpdateProfileEvent(
                                                name: nameController.text,
                                              ),
                                            );

                                            // Optional: Navigate or show success message
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
                                              )!.translate('save'),
                                              style: FTextStyle.buttonText,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Visibility(
                                  visible: !isEdit && !PrefUtils.getIsGuest(),
                                  child: GestureDetector(
                                    onTap:
                                        isLoading
                                            ? null // 🔒 Disable tap while loading
                                            : () {
                                              _showLogoutConfirmation(context);
                                            },
                                    child: Opacity(
                                      opacity:
                                          isLoading
                                              ? 0.6
                                              : 1.0, // Optional: dim button when disabled
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
                                          child:
                                              isLoading
                                                  ? SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child:
                                                        LoadingAnimationWidget.staggeredDotsWave(
                                                          color: Colors.white,
                                                          size: 24,
                                                        ),
                                                  )
                                                  : Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.translate('logout'),
                                                    style:
                                                        FTextStyle.buttonText,
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                Visibility(
                                  visible: PrefUtils.getIsGuest(),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LoginScreen(),
                                        ),
                                        (route) => false,
                                      );
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
                                          )!.translate('signInToContinue'),
                                          style: FTextStyle.buttonText,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
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
    );
  }
}
