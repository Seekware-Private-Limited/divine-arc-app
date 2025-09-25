part of 'auth_flow_bloc.dart';

@immutable
sealed class AuthFlowState {}

final class AuthFlowInitial extends AuthFlowState {}

// Google Login States
class GoogleLoginLoading extends AuthFlowState {}

class GoogleLoginSuccess extends AuthFlowState {
  final String name;
  final String email;
  final String image;
  final String id;
  GoogleLoginSuccess(this.name, this.email, this.image, this.id);
}

class GoogleLoginFailure extends AuthFlowState {
  final String errorMessage;
  GoogleLoginFailure(this.errorMessage);
}

// Facebook Login States
class FacebookLoginLoading extends AuthFlowState {}

class FacebookLoginSuccess extends AuthFlowState {
  final String name;
  final String email;
  final String profileImage;
  final String id;
  FacebookLoginSuccess(this.name, this.email, this.profileImage, this.id);
}

class FacebookLoginFailure extends AuthFlowState {
  final String error;
  FacebookLoginFailure(this.error);
}

// SignUp States
class SignUpLoading extends AuthFlowState {}

class SignUpSuccess extends AuthFlowState {
  final Map<String, dynamic> successResponse;
  SignUpSuccess(this.successResponse);
}

class SignUpFailure extends AuthFlowState {
  final Map<String, dynamic> failureResponse;
  SignUpFailure(this.failureResponse);
}

// Login States
class LoginLoading extends AuthFlowState {}

class LoginSuccess extends AuthFlowState {
  final Map<String, dynamic> successResponse;
  LoginSuccess(this.successResponse);
}

class LoginFailure extends AuthFlowState {
  final String failureMessage;
  LoginFailure(this.failureMessage);
}

// Social Login States
class SocialLoginLoading extends AuthFlowState {}

class SocialLoginSuccess extends AuthFlowState {
  final Map<String, dynamic> successResponse;
  SocialLoginSuccess(this.successResponse);
}

class SocialLoginFailure extends AuthFlowState {
  final String failureMessage;
  SocialLoginFailure(this.failureMessage);
}

// Forgot Password States
class ForgotPasswordLoading extends AuthFlowState {}

class ForgotPasswordSuccess extends AuthFlowState {
  final Map<String, dynamic> successResponse;
  ForgotPasswordSuccess(this.successResponse);
}

class ForgotPasswordFailure extends AuthFlowState {
  final Map<String, dynamic> failureResponse;
  ForgotPasswordFailure(this.failureResponse);
}

// Change Password StateStreamable
class ChangePasswordLoading extends AuthFlowState {}

class ChangePasswordSuccess extends AuthFlowState {
  final Map<String, dynamic> successResponse;
  ChangePasswordSuccess(this.successResponse);
}

class ChangePasswordFailure extends AuthFlowState {
  final Map<String, dynamic> failureResponse;
  ChangePasswordFailure(this.failureResponse);
}

// Common Server Failure State
class CommonServerFailure extends AuthFlowState {
  final String error;
  CommonServerFailure(this.error);
}

// Check Network Connection State
class CheckNetworkConnection extends AuthFlowState {}
