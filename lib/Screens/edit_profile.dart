import 'package:divine_arc/Utils/app_imports.dart';

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String profilePictureUrl;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.profilePictureUrl,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  String? uploadedImageUrl;

  bool isUpdating = false;
  bool isImageUploading = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.name;
    emailController.text = widget.email;
    uploadedImageUrl = widget.profilePictureUrl;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() => _imageFile = File(pickedFile.path));

    BlocProvider.of<HomeFlowBloc>(
      context,
    ).add(UploadFile(file: pickedFile.path));
  }

  ImageProvider _getProfileImage() {
    if (_imageFile != null) return FileImage(_imageFile!);
    if (uploadedImageUrl != null && uploadedImageUrl!.isNotEmpty) {
      return NetworkImage(uploadedImageUrl!);
    }
    return const AssetImage('assets/images/defaultProfile.jpg');
  }

  void _onSave() {
    if (nameController.text.trim().isEmpty) {
      CommonUtils.showErrorToast('Name cannot be empty');
      return;
    }

    BlocProvider.of<HomeFlowBloc>(context).add(
      UpdateProfileEvent(
        name: nameController.text.trim(),
        profilePicture: uploadedImageUrl ?? '',
      ),
    );
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
          body: BlocListener<HomeFlowBloc, HomeFlowState>(
            listener: (context, state) {
              if (state is UpdateProfileLoading) {
                setState(() => isUpdating = true);
              } else if (state is UpdateProfileLoaded) {
                setState(() => isUpdating = false);

                CommonUtils.showSuccessToast(
                  AppLocalizations.of(
                    context,
                  )!.translate('profileUpdatedSuccessfully'),
                );

                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'profile_picture': uploadedImageUrl,
                });
              } else if (state is UpdateProfileError) {
                setState(() => isUpdating = false);
                CommonUtils.showErrorToast(
                  state.failureResponse['message'] ?? 'Something went wrong',
                );
              }

              if (state is UploadFileLoading) {
                setState(() => isImageUploading = true);
              } else if (state is UploadFileSuccess) {
                uploadedImageUrl = state.successResponse['url'];
                setState(() => isImageUploading = false);
              } else if (state is UploadFileFailure) {
                setState(() => isImageUploading = false);
                CommonUtils.showErrorToast(
                  state.failureResponse['message'] ?? 'Image upload failed',
                );
              } else if (state is CheckNetworkConnectionHomeFlow) {
                setState(() {
                  isUpdating = false;
                  isImageUploading = false;
                });
                CommonUtils.showErrorToast(
                  AppLocalizations.of(
                    context,
                  )!.translate('nointernetConnection'),
                );
              } else if (state is SessionExpiredStateHome) {
                CommonUtils.showErrorToast(state.message);
                PrefUtils.clearAll();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Stack(
              children: [
                /// Background
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/bgGitaGPT.png',
                    fit: BoxFit.cover,
                  ),
                ),

                /// Content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.black,
                                size: 22,
                              ),
                            ),
                            const LanguageDropdown(),
                          ],
                        ),

                        const SizedBox(height: 30),

                        Text(
                          AppLocalizations.of(
                            context,
                          )!.translate('editProfile'),
                          style: FTextStyle.boldText,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.translate('editprofile_description'),
                          style: FTextStyle.defaultText,
                        ),

                        const SizedBox(height: 20),

                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.gradientStart,
                                width: 1.4,
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  /// Profile Image
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 100,
                                        backgroundImage: _getProfileImage(),
                                      ),
                                      if (isImageUploading)
                                        Container(
                                          height: 200,
                                          width: 200,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.4,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 1.5,
                                            ),
                                          ),
                                        ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.gradientStart,
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            onPressed:
                                                () => _pickImage(
                                                  ImageSource.gallery,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 40),

                                  /// Name
                                  TextFormField(
                                    controller: nameController,
                                    style: FTextStyle.defaultText,
                                    decoration: InputDecoration(
                                      hintText: 'Name',
                                      filled: true,
                                      fillColor: AppColors.GlobalBG,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  /// Email (FIXED)
                                  TextFormField(
                                    controller: emailController,
                                    readOnly: true,
                                    style: FTextStyle.defaultText,
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(
                                        context,
                                      )!.translate('emailAddress'),
                                      filled: true,
                                      fillColor: AppColors.GlobalBG,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 30),

                                  /// Save Button
                                  GestureDetector(
                                    onTap: isUpdating ? null : _onSave,
                                    child: Container(
                                      height: 46,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.gradientStart,
                                            AppColors.gradientEnd,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child:
                                            isUpdating
                                                ? LoadingAnimationWidget.staggeredDotsWave(
                                                  color: Colors.white,
                                                  size: 30,
                                                )
                                                : Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.translate('save'),
                                                  style: FTextStyle.buttonText,
                                                ),
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

                /// Full Screen Loader
                if (isUpdating)
                  Container(color: Colors.black.withOpacity(0.15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
