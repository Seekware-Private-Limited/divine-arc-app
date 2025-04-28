import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:gita_gpt/Screens/customtabbar.dart';
import 'package:gita_gpt/Screens/signup_screen.dart';
import 'package:gita_gpt/Utils/flutter_color_themes.dart';
import 'package:gita_gpt/Utils/flutter_font_style.dart';
import 'package:flutter_svg/flutter_svg.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? emailErrorText;
  final TextEditingController emailController = TextEditingController();

  // Email validation regex
  bool isValidEmail(String email) {
    return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.GlobalBG,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gradientStart,width: 1.5),
                color: AppColors.containerBG,
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Center(child: Text('Gitagpt',style: FTextStyle.gita_gpt_text)),
                  Text('Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmoda',style: FTextStyle.defaultText,textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailController,
                    style: FTextStyle.defaultText,
                    decoration: InputDecoration(
                      hintText: 'Email Address',
                      hintStyle: FTextStyle.defaultText,
                      filled: true,
                      fillColor: AppColors.GlobalBG,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                          emailErrorText = 'Email address is required.';
                        } else if (!isValidEmail(value)) {
                          emailErrorText = 'Please enter a valid email address.';
                        } else {
                          emailErrorText = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 5),
                  Visibility(
                    visible: emailErrorText !=null,
                      child: Text(emailErrorText ?? '',style: FTextStyle.errorTextStyle)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      if(emailController.text.isEmpty){
                        setState(() {
                          emailErrorText = 'Email is required.';
                        });
                      }
                      else if(isValidEmail(emailController.text)){
                        Navigator.push(context, MaterialPageRoute(builder: (context) => CustomBottomNavBar()));
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.gradientStart, AppColors.gradientEnd],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      height: 45,
                      width: double.infinity,
                      child: Center(child: Text('Sign In',style: FTextStyle.buttonText)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpScreen()),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Don’t have an account?',style: FTextStyle.defaultText),
                        const SizedBox(width:5),
                        Text('Sign Up',style: FTextStyle.defaultTextBold),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 45,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gradientStart,width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/images/google.svg',height: 24,width: 24),
                        const SizedBox(width: 16),
                        Text('Continue with Google',style: FTextStyle.socialloginbuttonText)
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 45,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gradientStart,width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/images/apple-logo.svg',height: 24,width: 24),
                        const SizedBox(width: 16),
                        Text('Continue with Apple',style: FTextStyle.socialloginbuttonText)
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 45,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gradientStart,width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/images/microsoft.svg',height: 24,width: 24),
                        const SizedBox(width: 16),
                        Text('Continue with Microsoft',style: FTextStyle.socialloginbuttonText)
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Powered By',style: FTextStyle.defaultText),
                      const SizedBox(width: 5),
                      SvgPicture.asset('assets/images/vex.svg',height: 16,width: 16)
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
      ),
    );
  }
}
