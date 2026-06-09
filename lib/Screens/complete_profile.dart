// import 'package:divine_arc/APIs/AuthFlow/auth_flow_bloc.dart';
// import 'package:divine_arc/Utils/app_imports.dart';
// import 'package:divine_arc/Utils/session_expired_snackbar.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';

// class CompleteProfileScreen extends StatefulWidget {
//   const CompleteProfileScreen({super.key});

//   @override
//   State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
// }

// class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
//   bool isLoading = false;
//   String? selectedGender;
//   String? backendFormattedDob;

//   final TextEditingController dobController = TextEditingController();
//   final TextEditingController placeofbirthController = TextEditingController();
//   final TextEditingController genderController = TextEditingController();
//   final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

//   @override
//   void dispose() {
//     dobController.dispose();
//     placeofbirthController.dispose();
//     genderController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         FocusScope.of(context).unfocus();
//       },
//       child: MediaQuery(
//         data: MediaQuery.of(
//           context,
//         ).copyWith(textScaler: const TextScaler.linear(1)),
//         child: Scaffold(
//           resizeToAvoidBottomInset: true,
//           body: Stack(
//             children: [
//               Positioned.fill(
//                 child: Image.asset(
//                   'assets/images/bgGitaGPT.png',
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               SafeArea(
//                 child: Center(
//                   child: SingleChildScrollView(
//                     child: BlocListener<AuthFlowBloc, AuthFlowState>(
//                       listener: (context, state) async {
//                         if (state is CompleteProfileLoading) {
//                           setState(() {
//                             isLoading = true;
//                           });
//                         } else if (state is CompleteProfileSuccess) {
//                           setState(() {
//                             isLoading = false;
//                           });
//                           CommonUtils.showSuccessToast(
//                             'Profile Completed Successfully!',
//                           );
//                           Navigator.pushAndRemoveUntil(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => CustomBottomNavBar(),
//                             ),
//                             (route) => false,
//                           );
//                         } else if (state is CompleteProfileFailure) {
//                           setState(() {
//                             isLoading = false;
//                           });
//                           CommonUtils.showErrorToast(
//                             state.failureResponse['message'],
//                           );
//                         } else if (state is SessionExpiredStateAuth) {
//                           setState(() {
//                             isLoading = false;
//                           });
//                           SessionExpiredSnackBar.show(
//                             context: context,
//                             message: state.message,
//                           );
//                         }
//                       },
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 20),
//                         child: Column(
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 const LanguageDropdown(),
//                                 GestureDetector(
//                                   onTap: () async {
//                                     await _analytics.logEvent(
//                                       name: 'CompleteProfileSkipTapped',
//                                     );
//                                     Navigator.pushAndRemoveUntil(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder:
//                                             (context) => CustomBottomNavBar(),
//                                       ),
//                                       (route) => false,
//                                     );
//                                   },
//                                   child: Row(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.center,
//                                     children: [
//                                       Text(
//                                         AppLocalizations.of(
//                                           context,
//                                         )!.translate('skip'),
//                                         style: FTextStyle.defaultTextBold,
//                                       ),
//                                       const SizedBox(width: 4),
//                                       const Icon(Icons.skip_next, size: 18),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 20),
//                             Container(
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(10),
//                                 border: Border.all(
//                                   color: AppColors.gradientStart,
//                                   width: 1.5,
//                                 ),
//                                 color: AppColors.containerBG,
//                               ),
//                               padding: const EdgeInsets.all(25),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceEvenly,
//                                 children: [
//                                   Center(
//                                     child: ClipRRect(
//                                       borderRadius: BorderRadius.circular(100),
//                                       child: Image.asset(
//                                         'assets/images/DivineArcLogo.png',
//                                         height: 100,
//                                         width: 100,
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 16),
//                                   Center(
//                                     child: Text(
//                                       AppLocalizations.of(
//                                             context,
//                                           )!.translate('completeProfile') ??
//                                           'Complete Profile',
//                                       style: FTextStyle.boldText,
//                                       textAlign: TextAlign.center,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 20),
//                                   Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 12,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: AppColors.GlobalBG,
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     child: DropdownButtonHideUnderline(
//                                       child: DropdownButton<String>(
//                                         value: selectedGender,
//                                         isExpanded: true,
//                                         dropdownColor: AppColors.GlobalBG,
//                                         hint: Text(
//                                           AppLocalizations.of(
//                                             context,
//                                           )!.translate('gender'),
//                                           style: FTextStyle.defaultText
//                                               .copyWith(color: Colors.black),
//                                         ),
//                                         icon: Icon(
//                                           Icons.keyboard_arrow_down_rounded,
//                                           color: AppColors.gradientStart,
//                                         ),
//                                         style: FTextStyle.defaultText,
//                                         items: [
//                                           DropdownMenuItem(
//                                             value: 'Male',
//                                             child: Text(
//                                               AppLocalizations.of(
//                                                 context,
//                                               )!.translate('male'),
//                                             ),
//                                           ),
//                                           DropdownMenuItem(
//                                             value: 'Female',
//                                             child: Text(
//                                               AppLocalizations.of(
//                                                 context,
//                                               )!.translate('female'),
//                                             ),
//                                           ),
//                                           DropdownMenuItem(
//                                             value: 'Other',
//                                             child: Text(
//                                               AppLocalizations.of(
//                                                 context,
//                                               )!.translate('other'),
//                                             ),
//                                           ),
//                                         ],
//                                         onChanged: (value) {
//                                           setState(() {
//                                             selectedGender = value;
//                                             genderController.text =
//                                                 value != null
//                                                     ? value.toLowerCase()
//                                                     : '';
//                                           });
//                                         },
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 10),
//                                   TextFormField(
//                                     controller: dobController,
//                                     readOnly: true,
//                                     style: FTextStyle.defaultText,
//                                     decoration: InputDecoration(
//                                       hintText: AppLocalizations.of(
//                                         context,
//                                       )!.translate('date_of_birth'),
//                                       hintStyle: FTextStyle.defaultText,
//                                       filled: true,
//                                       fillColor: AppColors.GlobalBG,
//                                       contentPadding:
//                                           const EdgeInsets.symmetric(
//                                             horizontal: 12,
//                                             vertical: 14,
//                                           ),
//                                       border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(8),
//                                         borderSide: BorderSide.none,
//                                       ),
//                                       suffixIcon: Icon(
//                                         Icons.calendar_month_rounded,
//                                         color: AppColors.gradientStart,
//                                       ),
//                                     ),
//                                     onTap: () async {
//                                       FocusScope.of(context).unfocus();
//                                       final pickedDate = await showDatePicker(
//                                         context: context,
//                                         initialDate: DateTime.now(),
//                                         firstDate: DateTime(1900),
//                                         lastDate: DateTime.now(),
//                                         builder: (context, child) {
//                                           return Theme(
//                                             data: Theme.of(context).copyWith(
//                                               colorScheme:
//                                                   const ColorScheme.light(
//                                                     primary:
//                                                         AppColors.gradientStart,
//                                                     onPrimary: Colors.white,
//                                                     surface:
//                                                         AppColors.containerBG,
//                                                     onSurface: Colors.black,
//                                                   ),
//                                               scaffoldBackgroundColor:
//                                                   AppColors.containerBG,
//                                               dialogBackgroundColor:
//                                                   AppColors.containerBG,
//                                               textTheme: Theme.of(
//                                                 context,
//                                               ).textTheme.copyWith(
//                                                 headlineLarge:
//                                                     FTextStyle
//                                                         .defaultTextSemiBold,
//                                                 headlineMedium:
//                                                     FTextStyle
//                                                         .defaultTextSemiBold,
//                                                 titleLarge:
//                                                     FTextStyle
//                                                         .defaultTextSemiBold,
//                                                 bodyLarge:
//                                                     FTextStyle.defaultText,
//                                                 bodyMedium:
//                                                     FTextStyle.defaultText,
//                                                 labelLarge:
//                                                     FTextStyle.defaultTextBold,
//                                               ),
//                                               textButtonTheme:
//                                                   TextButtonThemeData(
//                                                     style: TextButton.styleFrom(
//                                                       foregroundColor:
//                                                           AppColors
//                                                               .gradientStart,
//                                                       textStyle:
//                                                           FTextStyle
//                                                               .defaultTextBold,
//                                                     ),
//                                                   ),
//                                               datePickerTheme: DatePickerThemeData(
//                                                 backgroundColor:
//                                                     AppColors.containerBG,
//                                                 headerBackgroundColor:
//                                                     AppColors.gradientStart,
//                                                 headerForegroundColor:
//                                                     Colors.white,
//                                                 dayStyle:
//                                                     FTextStyle.defaultText,
//                                                 yearStyle:
//                                                     FTextStyle.defaultText,
//                                                 todayForegroundColor:
//                                                     WidgetStateProperty.all(
//                                                       Colors.black,
//                                                     ),
//                                                 todayBorder: const BorderSide(
//                                                   color: Colors.black,
//                                                   width: 1.5,
//                                                 ),
//                                                 confirmButtonStyle:
//                                                     TextButton.styleFrom(
//                                                       foregroundColor:
//                                                           AppColors
//                                                               .gradientStart,
//                                                       textStyle:
//                                                           FTextStyle
//                                                               .defaultTextBold,
//                                                     ),
//                                                 cancelButtonStyle:
//                                                     TextButton.styleFrom(
//                                                       foregroundColor:
//                                                           AppColors
//                                                               .gradientStart,
//                                                       textStyle:
//                                                           FTextStyle
//                                                               .defaultTextBold,
//                                                     ),
//                                               ),
//                                             ),
//                                             child: child!,
//                                           );
//                                         },
//                                       );

//                                       if (pickedDate != null) {
//                                         setState(() {
//                                           dobController.text =
//                                               "${pickedDate.day.toString().padLeft(2, '0')}/"
//                                               "${pickedDate.month.toString().padLeft(2, '0')}/"
//                                               "${pickedDate.year}";
//                                           backendFormattedDob =
//                                               "${pickedDate.year}-"
//                                               "${pickedDate.month.toString().padLeft(2, '0')}-"
//                                               "${pickedDate.day.toString().padLeft(2, '0')}";
//                                         });
//                                       }
//                                     },
//                                   ),
//                                   const SizedBox(height: 10),
//                                   TextFormField(
//                                     controller: placeofbirthController,
//                                     style: FTextStyle.defaultText,
//                                     decoration: InputDecoration(
//                                       hintText: AppLocalizations.of(
//                                         context,
//                                       )!.translate('place_of_birth'),
//                                       hintStyle: FTextStyle.defaultText,
//                                       filled: true,
//                                       fillColor: AppColors.GlobalBG,
//                                       contentPadding:
//                                           const EdgeInsets.symmetric(
//                                             horizontal: 12,
//                                             vertical: 14,
//                                           ),
//                                       border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(8),
//                                         borderSide: BorderSide.none,
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 24),
//                                   GestureDetector(
//                                     onTap:
//                                         isLoading
//                                             ? null
//                                             : () async {
//                                               await _analytics.logEvent(
//                                                 name:
//                                                     'CompleteProfileSubmitClicked',
//                                                 parameters: {
//                                                   'gender':
//                                                       genderController.text
//                                                           .trim(),
//                                                   'place_of_birth':
//                                                       placeofbirthController
//                                                           .text
//                                                           .trim(),
//                                                 },
//                                               );
//                                               BlocProvider.of<AuthFlowBloc>(
//                                                 context,
//                                               ).add(
//                                                 CompleteProfileEvent(
//                                                   gender:
//                                                       genderController.text
//                                                           .trim(),
//                                                   dateOfBirth:
//                                                       (backendFormattedDob ??
//                                                               dobController
//                                                                   .text)
//                                                           .trim(),
//                                                   placeOfBirth:
//                                                       placeofbirthController
//                                                           .text
//                                                           .trim(),
//                                                 ),
//                                               );
//                                             },
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         gradient: LinearGradient(
//                                           begin: Alignment.topCenter,
//                                           end: Alignment.bottomCenter,
//                                           colors: [
//                                             AppColors.gradientStart,
//                                             AppColors.gradientEnd,
//                                           ],
//                                         ),
//                                         borderRadius: BorderRadius.circular(10),
//                                       ),
//                                       height: 45,
//                                       width: double.infinity,
//                                       child: Center(
//                                         child:
//                                             isLoading
//                                                 ? const CircularProgressIndicator(
//                                                   color: Colors.white,
//                                                 )
//                                                 : Text(
//                                                   AppLocalizations.of(
//                                                         context,
//                                                       )!.translate('submit') ??
//                                                       'Submit',
//                                                   style: FTextStyle.buttonText,
//                                                 ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
