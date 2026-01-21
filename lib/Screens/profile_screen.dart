import 'package:divine_arc/Screens/change_password_screen.dart';
import 'package:divine_arc/Utils/app_imports.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool nameError = false;
  String? nameErrorText;
  bool isLoading = false;
  bool isEdit = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  String? profilePictureUrl;
  String? userName;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    BlocProvider.of<HomeFlowBloc>(context).add(ViewUserProfile());
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);

    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);

      const maxSize = 5 * 1024 * 1024;
      if (await imageFile.length() > maxSize) {
        CommonUtils.showErrorToast('Image size too large. Max 5MB allowed.');
        return;
      }

      setState(() {
        _imageFile = imageFile;
      });

      BlocProvider.of<HomeFlowBloc>(
        context,
      ).add(UploadProfilePhoto(file: imageFile.path));
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Container(
            padding: const EdgeInsets.all(20),
            height: 160,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: Text(
                    'Take From Camera',
                    style: FTextStyle.defaultText,
                  ),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo),
                  title: Text(
                    'Take From Gallery',
                    style: FTextStyle.defaultText,
                  ),
                  onTap: () => _pickImage(ImageSource.gallery),
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        body: BlocListener<HomeFlowBloc, HomeFlowState>(
          listener: (context, state) {
            if (state is LogoutLoading) {
              setState(() => isLoading = true);
            } else if (state is LogoutSuccess) {
              setState(() => isLoading = false);
              PrefUtils.clearAll();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
              CommonUtils.showSuccessToast(
                AppLocalizations.of(
                  context,
                )!.translate('loggedoutsuccessfully'),
              );
            } else if (state is LogoutFailure) {
              setState(() => isLoading = false);
              CommonUtils.showErrorToast(
                state.failureResponse['message'] ?? 'Logout failed',
              );
            } else if (state is UpdateProfileLoading) {
              setState(() => isLoading = true);
            } else if (state is UpdateProfileLoaded) {
              setState(() {
                isLoading = false;
                isEdit = false;
              });
              BlocProvider.of<HomeFlowBloc>(context).add(ViewUserProfile());
              CommonUtils.showSuccessToast(
                AppLocalizations.of(
                  context,
                )!.translate('profileUpdatedSuccessfully'),
              );
            } else if (state is UpdateProfileError) {
              setState(() => isLoading = false);
              CommonUtils.showErrorToast(
                state.failureResponse['message'] ?? 'Update failed',
              );
            } else if (state is UploadProfilePhotoSuccess) {
              final newUrl = state.successResponse['url'];
              if (newUrl != null) {
                setState(() {
                  profilePictureUrl = newUrl;
                  _imageFile = null;
                });
                BlocProvider.of<HomeFlowBloc>(context).add(
                  UpdateProfileEvent(
                    name: nameController.text,
                    profilePicture: profilePictureUrl ?? '',
                  ),
                );
              }
            } else if (state is UploadProfilePhotoFailure) {
              setState(() => _imageFile = null);
              CommonUtils.showErrorToast(
                state.failureResponse['message'] ?? 'Upload failed',
              );
            } else if (state is UserProfileLoading) {
              setState(() => isLoading = true);
            } else if (state is UserProfileLoaded) {
              setState(() => isLoading = false);
              final response = state.successResponse;
              userName = response['data']['name'] ?? '';
              userEmail = response['data']['email'] ?? '';
              profilePictureUrl = response['data']['profile_picture'] ?? '';
              nameController.text = userName ?? PrefUtils.getName();
              emailController.text = userEmail ?? PrefUtils.getEmail();
            } else if (state is UserProfileError) {
              setState(() => isLoading = false);
              CommonUtils.showErrorToast(
                state.failureResponse['message'] ?? 'Failed to load profile',
              );
            } else if (state is CommonServerFailureHome) {
              setState(() => isLoading = false);
              CommonUtils.showErrorToast('Server error. Please try again.');
            } else if (state is CheckNetworkConnectionHomeFlow) {
              setState(() => isLoading = false);
              CommonUtils.showErrorToast('No internet connection');
            } else if (state is SessionExpiredStateHome) {
              setState(() => isLoading = false);
              CommonUtils.showErrorToast(state.message);
              PrefUtils.clearAll();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          },
          child: BlocBuilder<HomeFlowBloc, HomeFlowState>(
            builder: (context, state) {
              final isUploading = state is UploadProfilephotoLoading;
              final isProfileLoading =
                  state is UserProfileLoading && userName == null;

              return Stack(
                children: [
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
                              child:
                                  isProfileLoading
                                      ? Center(
                                        child:
                                            LoadingAnimationWidget.staggeredDotsWave(
                                              color: AppColors.gradientStart,
                                              size: 40,
                                            ),
                                      )
                                      : SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              PrefUtils.getIsGuest()
                                                  ? MainAxisAlignment
                                                      .spaceEvenly
                                                  : MainAxisAlignment.center,
                                          children: [
                                            if (!PrefUtils.getIsGuest())
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: GestureDetector(
                                                  onTap:
                                                      () => setState(
                                                        () => isEdit = !isEdit,
                                                      ),
                                                  child: Image.asset(
                                                    isEdit
                                                        ? 'assets/images/close.png'
                                                        : 'assets/images/edit.png',
                                                    height: isEdit ? 15 : 24,
                                                    width: isEdit ? 15 : 24,
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
                                                          _imageFile != null
                                                              ? Image.file(
                                                                _imageFile!,
                                                                fit:
                                                                    BoxFit
                                                                        .cover,
                                                              )
                                                              : (profilePictureUrl !=
                                                                      null &&
                                                                  profilePictureUrl!
                                                                      .isNotEmpty)
                                                              ? Image.network(
                                                                profilePictureUrl!,
                                                                fit:
                                                                    BoxFit
                                                                        .cover,
                                                                errorBuilder:
                                                                    (
                                                                      context,
                                                                      error,
                                                                      stackTrace,
                                                                    ) => Image.asset(
                                                                      'assets/images/defaultProfile.jpg',
                                                                      fit:
                                                                          BoxFit
                                                                              .cover,
                                                                    ),
                                                              )
                                                              : Image.asset(
                                                                'assets/images/defaultProfile.jpg',
                                                                fit:
                                                                    BoxFit
                                                                        .cover,
                                                              ),
                                                    ),
                                                  ),
                                                  if (isUploading)
                                                    Container(
                                                      height: 120,
                                                      width: 120,
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withOpacity(0.3),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Center(
                                                        child: SizedBox(
                                                          height: 26,
                                                          width: 26,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2.5,
                                                            color:
                                                                AppColors
                                                                    .gradientStart,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  if (!isUploading &&
                                                      !PrefUtils.getIsGuest())
                                                    Positioned(
                                                      bottom: 0,
                                                      right: 0,
                                                      child: GestureDetector(
                                                        onTap:
                                                            () =>
                                                                _showImageSourceActionSheet(
                                                                  context,
                                                                ),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                6,
                                                              ),
                                                          decoration:
                                                              BoxDecoration(
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                border: Border.all(
                                                                  color:
                                                                      Colors
                                                                          .grey,
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
                                                        )!.translate(
                                                          'guestDescription',
                                                        ),
                                                        style:
                                                            FTextStyle
                                                                .socialloginbuttonText,
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                                : Column(
                                                  children: [
                                                    const SizedBox(height: 10),
                                                    Center(
                                                      child: Text(
                                                        userName ??
                                                            PrefUtils.getName(),
                                                        style:
                                                            FTextStyle
                                                                .defaultText,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Center(
                                                      child: Text(
                                                        userEmail ??
                                                            PrefUtils.getEmail(),
                                                        style:
                                                            FTextStyle
                                                                .defaultText,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            const SizedBox(height: 30),
                                            if (!PrefUtils.getIsGuest())
                                              TextFormField(
                                                controller: nameController,
                                                readOnly: !isEdit,
                                                style: FTextStyle.defaultText,
                                                decoration: InputDecoration(
                                                  hintText: AppLocalizations.of(
                                                    context,
                                                  )!.translate('name'),
                                                  hintStyle:
                                                      FTextStyle.defaultText,
                                                  filled: true,
                                                  fillColor: AppColors.GlobalBG,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 14,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    if (value.isEmpty) {
                                                      nameError = true;
                                                      nameErrorText =
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.translate(
                                                            'emptyNameError',
                                                          );
                                                    } else {
                                                      nameError = false;
                                                      nameErrorText = null;
                                                    }
                                                  });
                                                },
                                              ),
                                            if (nameError)
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    nameErrorText ?? '',
                                                    style:
                                                        FTextStyle
                                                            .errorTextStyle,
                                                  ),
                                                ],
                                              ),
                                            const SizedBox(height: 10),
                                            if (!PrefUtils.getIsGuest())
                                              TextFormField(
                                                controller: emailController,
                                                readOnly: true,
                                                style: FTextStyle.defaultText,
                                                decoration: InputDecoration(
                                                  hintText: AppLocalizations.of(
                                                    context,
                                                  )!.translate('emailAddress'),
                                                  hintStyle:
                                                      FTextStyle.defaultText,
                                                  filled: true,
                                                  fillColor: AppColors.GlobalBG,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 14,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 10),
                                            if (isEdit &&
                                                !PrefUtils.getIsSocialLogin())
                                              Column(
                                                children: [
                                                  const SizedBox(height: 16),
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(
                                                        () => isEdit = false,
                                                      );
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (context) =>
                                                                  const ChangePasswordScreen(),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin:
                                                              Alignment
                                                                  .topCenter,
                                                          end:
                                                              Alignment
                                                                  .bottomCenter,
                                                          colors: [
                                                            AppColors
                                                                .gradientStart,
                                                            AppColors
                                                                .gradientEnd,
                                                          ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      height: 45,
                                                      width: double.infinity,
                                                      child: Center(
                                                        child: Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.translate(
                                                            'updatePassword',
                                                          ),
                                                          style:
                                                              FTextStyle
                                                                  .buttonText,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (isEdit)
                                              Column(
                                                children: [
                                                  const SizedBox(height: 16),
                                                  GestureDetector(
                                                    onTap:
                                                        isLoading
                                                            ? null
                                                            : () {
                                                              setState(
                                                                () =>
                                                                    nameError =
                                                                        false,
                                                              );

                                                              if (nameController
                                                                  .text
                                                                  .isEmpty) {
                                                                setState(() {
                                                                  nameError =
                                                                      true;
                                                                  nameErrorText =
                                                                      AppLocalizations.of(
                                                                        context,
                                                                      )!.translate(
                                                                        'emptyNameError',
                                                                      );
                                                                });
                                                                return;
                                                              }

                                                              BlocProvider.of<
                                                                HomeFlowBloc
                                                              >(context).add(
                                                                UpdateProfileEvent(
                                                                  name:
                                                                      nameController
                                                                          .text,
                                                                  profilePicture:
                                                                      profilePictureUrl ??
                                                                      '',
                                                                ),
                                                              );
                                                            },
                                                    child: Opacity(
                                                      opacity:
                                                          isLoading ? 0.6 : 1.0,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            begin:
                                                                Alignment
                                                                    .topCenter,
                                                            end:
                                                                Alignment
                                                                    .bottomCenter,
                                                            colors: [
                                                              AppColors
                                                                  .gradientStart,
                                                              AppColors
                                                                  .gradientEnd,
                                                            ],
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
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
                                                                    child: LoadingAnimationWidget.staggeredDotsWave(
                                                                      color:
                                                                          Colors
                                                                              .white,
                                                                      size: 24,
                                                                    ),
                                                                  )
                                                                  : Text(
                                                                    AppLocalizations.of(
                                                                      context,
                                                                    )!.translate(
                                                                      'save',
                                                                    ),
                                                                    style:
                                                                        FTextStyle
                                                                            .buttonText,
                                                                  ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            const SizedBox(height: 16),
                                            if (!isEdit &&
                                                !PrefUtils.getIsGuest())
                                              GestureDetector(
                                                onTap:
                                                    isLoading
                                                        ? null
                                                        : () =>
                                                            _showLogoutConfirmation(
                                                              context,
                                                            ),
                                                child: Opacity(
                                                  opacity:
                                                      isLoading ? 0.6 : 1.0,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end:
                                                            Alignment
                                                                .bottomCenter,
                                                        colors: [
                                                          AppColors
                                                              .gradientStart,
                                                          AppColors.gradientEnd,
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
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
                                                                child: LoadingAnimationWidget.staggeredDotsWave(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  size: 24,
                                                                ),
                                                              )
                                                              : Text(
                                                                AppLocalizations.of(
                                                                  context,
                                                                )!.translate(
                                                                  'logout',
                                                                ),
                                                                style:
                                                                    FTextStyle
                                                                        .buttonText,
                                                              ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (PrefUtils.getIsGuest())
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.pushAndRemoveUntil(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              const LoginScreen(),
                                                    ),
                                                    (route) => false,
                                                  );
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin:
                                                          Alignment.topCenter,
                                                      end:
                                                          Alignment
                                                              .bottomCenter,
                                                      colors: [
                                                        AppColors.gradientStart,
                                                        AppColors.gradientEnd,
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  height: 45,
                                                  width: double.infinity,
                                                  child: Center(
                                                    child: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.translate(
                                                        'signInToContinue',
                                                      ),
                                                      style:
                                                          FTextStyle.buttonText,
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
              );
            },
          ),
        ),
      ),
    );
  }
}
