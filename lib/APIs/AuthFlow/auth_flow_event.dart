part of 'auth_flow_bloc.dart';

@immutable
sealed class AuthFlowEvent {}

// Google Login Event
class GoogleLoginEventHandler extends AuthFlowEvent {}

// Facebook Login Event
class FacebookLoginEventHandler extends AuthFlowEvent {}

// Sign Up Event
class SignupEventHandler extends AuthFlowEvent {
  final String name;
  final String email;
  final String password;
  SignupEventHandler({
    required this.name,
    required this.email,
    required this.password,
  });
}

// Login Event
class LoginEventHandler extends AuthFlowEvent {
  final String email;
  final String password;
  LoginEventHandler({required this.email, required this.password});
}

// Social Login Event
class SocialLoginEventHandler extends AuthFlowEvent {
  final String socialId;
  final String socialType;
  final String email;
  SocialLoginEventHandler({
    required this.socialId,
    required this.socialType,
    required this.email,
  });
}

// Forgot Password Event
class ForgotPasswordEventHandler extends AuthFlowEvent {
  final String email;
  ForgotPasswordEventHandler({required this.email});
}

// Change Password Event
class ChangePasswordEventHandler extends AuthFlowEvent {
  final String currentPassword;
  final String newPassword;
  ChangePasswordEventHandler({
    required this.currentPassword,
    required this.newPassword,
  });
}
