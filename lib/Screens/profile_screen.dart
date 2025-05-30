import 'package:gita_gpt/APIs/HomeFlow/home_flow_bloc.dart';
import 'package:gita_gpt/Utils/app_imports.dart';
import 'package:gita_gpt/Utils/common_utils.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
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
                    vertical: 20,
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
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.gradientStart,
                              width: 1.5,
                            ),
                            color: Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () {
                                    _showLogoutConfirmation(context);
                                  },
                                  child:
                                      isLoading
                                          ? LoadingAnimationWidget.staggeredDotsWave(
                                            color: AppColors.gradientStart,
                                            size: 24,
                                          )
                                          : Image.asset(
                                            'assets/images/logout.png',
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
                                              color: AppColors.gradientStart,
                                            ),
                                          ),
                                          child: Image.asset(
                                            'assets/images/edit.png',
                                            height: 18,
                                            width: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('princeSingh'),
                                  style: FTextStyle.defaultText,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('princeEmail'),
                                  style: FTextStyle.defaultText,
                                ),
                              ),
                              const SizedBox(height: 30),

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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5),
                                    Text(
                                      passwordErrorText ?? '',
                                      style: FTextStyle.errorTextStyle,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Save Button
                              GestureDetector(
                                onTap: () {
                                  if (nameController.text.isEmpty) {
                                    setState(() {
                                      nameError = true;
                                      nameErrorText = AppLocalizations.of(
                                        context,
                                      )!.translate('emptyNameError');
                                    });
                                  }
                                  if (emailController.text.isEmpty) {
                                    setState(() {
                                      emailError = true;
                                      emailErrorText = AppLocalizations.of(
                                        context,
                                      )!.translate('emptyEmailError');
                                    });
                                  }
                                  if (passwordController.text.isEmpty) {
                                    setState(() {
                                      passwordError = true;
                                      passwordErrorText = AppLocalizations.of(
                                        context,
                                      )!.translate('emptyPasswordError');
                                    });
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
                                      )!.translate('save'),
                                      style: FTextStyle.buttonText,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
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
