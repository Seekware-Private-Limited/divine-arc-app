import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/session_expired_snackbar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String profilePictureUrl;
  final String? gender;
  final String? dob;
  final String? placeOfBirth;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.profilePictureUrl,
    this.gender,
    this.dob,
    this.placeOfBirth,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController placeofbirthController = TextEditingController();
  final TextEditingController genderController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  File? _imageFile;
  String? uploadedImageUrl;
  String? selectedGender;
  String? backendFormattedDob;

  bool isUpdating = false;
  bool isImageUploading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    nameController.text = widget.name;
    emailController.text = widget.email;
    uploadedImageUrl = widget.profilePictureUrl;

    if (widget.gender != null && widget.gender!.isNotEmpty) {
      genderController.text = widget.gender!.toLowerCase();
      selectedGender =
          widget.gender![0].toUpperCase() +
          widget.gender!.substring(1).toLowerCase();
    }

    if (widget.dob != null && widget.dob!.isNotEmpty) {
      try {
        DateTime parsedDate = DateTime.parse(widget.dob!);
        dobController.text =
            "${parsedDate.day.toString().padLeft(2, '0')}/"
            "${parsedDate.month.toString().padLeft(2, '0')}/"
            "${parsedDate.year}";
        backendFormattedDob =
            "${parsedDate.year}-"
            "${parsedDate.month.toString().padLeft(2, '0')}-"
            "${parsedDate.day.toString().padLeft(2, '0')}";
      } catch (_) {
        dobController.text = widget.dob!;
        backendFormattedDob = widget.dob!;
      }
    }

    placeofbirthController.text = widget.placeOfBirth ?? '';
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    dobController.dispose();
    placeofbirthController.dispose();
    genderController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _analytics.logEvent(name: 'UserIsOnEditProfileSceen');
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
        gender: genderController.text.trim(),
        dateOfBirth: (backendFormattedDob ?? dobController.text).trim(),
        placeOfBirth: placeofbirthController.text.trim(),
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
                  'gender': genderController.text.trim(),
                  'date_of_birth':
                      (backendFormattedDob ?? dobController.text).trim(),
                  'place_of_birth': placeofbirthController.text.trim(),
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
                SessionExpiredSnackBar.show(
                  context: context,
                  message: state.message,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const CustomBackButton(),
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

                                  const SizedBox(height: 30),

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
                if (isUpdating)
                  Container(color: Colors.black.withValues(alpha: .15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
