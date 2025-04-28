import '../Utils/app_imports.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool nameError = false;
  bool emailError = false;
  bool passwordError = false;
  String? nameErrorText;
  String? emailErrorText;
  String? passwordErrorText;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Email validation regex
  bool isValidEmail(String email) {
    return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
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
                border: Border.all(color: AppColors.gradientStart, width: 1.5),
                color: AppColors.containerBG,
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Center(child: Text('Gitagpt', style: FTextStyle.gita_gpt_text)),
                  Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmoda',
                    style: FTextStyle.defaultText,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // Name Field
                  TextFormField(
                    controller: nameController,
                    style: FTextStyle.defaultText,
                    decoration: InputDecoration(
                      hintText: 'Name',
                      hintStyle: FTextStyle.defaultText,
                      filled: true,
                      fillColor: AppColors.GlobalBG,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value.isEmpty) {
                          nameError = true;
                          nameErrorText = 'Name is required.';
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
                        Text(nameErrorText ?? '', style: FTextStyle.errorTextStyle),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Email Field
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
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value.isEmpty) {
                          emailError = true;
                          emailErrorText = 'Email is required.';
                        } else if (!isValidEmail(value)) {
                          emailError = true;
                          emailErrorText = 'Please enter a valid email address.';
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
                        Text(emailErrorText ?? '', style: FTextStyle.errorTextStyle),
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
                      hintText: 'Password',
                      hintStyle: FTextStyle.defaultText,
                      filled: true,
                      fillColor: AppColors.GlobalBG,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value.isEmpty) {
                          passwordError = true;
                          passwordErrorText = 'Password is required';
                        } else if (value.length < 6) {
                          passwordError = true;
                          passwordErrorText = 'Password should be at least 6 characters';
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
                        Text(passwordErrorText ?? '', style: FTextStyle.errorTextStyle),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      if (nameController.text.isEmpty){
                        setState(() {
                          nameError = true;
                          nameErrorText = 'Name is required.';
                        });
                      }
                      if(emailController.text.isEmpty){
                        setState(() {
                          emailError = true;
                          emailErrorText = 'Email is required.';
                        });
                      }
                       if(passwordController.text.isEmpty){
                        setState(() {
                          passwordError = true;
                          passwordErrorText = 'Password is required.';
                        });
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
                      child: Center(child: Text('Sign Up', style: FTextStyle.buttonText)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account?', style: FTextStyle.defaultText),
                        const SizedBox(width: 5),
                        Text('Sign In', style: FTextStyle.defaultTextBold),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Social Login Buttons (Google, Apple, Microsoft)
                  Container(
                    height: 45,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gradientStart, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/images/google.svg', height: 24, width: 24),
                        const SizedBox(width: 16),
                        Text('Continue with Google', style: FTextStyle.socialloginbuttonText)
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 45,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gradientStart, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/images/apple-logo.svg', height: 24, width: 24),
                        const SizedBox(width: 16),
                        Text('Continue with Apple', style: FTextStyle.socialloginbuttonText)
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 45,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gradientStart, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/images/microsoft.svg', height: 24, width: 24),
                        const SizedBox(width: 16),
                        Text('Continue with Microsoft', style: FTextStyle.socialloginbuttonText)
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Powered By', style: FTextStyle.defaultText),
                      const SizedBox(width: 5),
                      SvgPicture.asset('assets/images/vex.svg', height: 16, width: 16)
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
