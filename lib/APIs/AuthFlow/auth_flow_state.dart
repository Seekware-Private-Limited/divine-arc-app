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

// Change Password States
class ChangePasswordLoading extends AuthFlowState {}

class ChangePasswordSuccess extends AuthFlowState {
  final Map<String, dynamic> successResponse;
  ChangePasswordSuccess(this.successResponse);
}

class ChangePasswordFailure extends AuthFlowState {
  final Map<String, dynamic> failureResponse;
  ChangePasswordFailure(this.failureResponse);
}

// Send Device Token States
class DeviceTokenSending extends AuthFlowState {}

class DeviceTokenSentSuccess extends AuthFlowState {
  final Map<String, dynamic> successResponse;
  DeviceTokenSentSuccess(this.successResponse);
}

class DeviceTokenSendFailure extends AuthFlowState {
  final Map<String, dynamic> failureResponse;
  DeviceTokenSendFailure(this.failureResponse);
}

// View App Config States
class ViewAppConfigLoading extends AuthFlowState {}

class ViewAppConfigLoaded extends AuthFlowState {
  final Map<String, dynamic> successResponse;
  ViewAppConfigLoaded(this.successResponse);
}

class ViewAppConfigFailure extends AuthFlowState {
  final Map<String, dynamic> failureResponse;
  ViewAppConfigFailure(this.failureResponse);
}

// Complete Profile When Social Login States
class CompleteProfileLoading extends AuthFlowState {}

class CompleteProfileSuccess extends AuthFlowState {
  final Map<String, dynamic> successResponse;
  CompleteProfileSuccess(this.successResponse);
}

class CompleteProfileFailure extends AuthFlowState {
  final Map<String, dynamic> failureResponse;
  CompleteProfileFailure(this.failureResponse);
}

class SessionExpiredStateAuth extends AuthFlowState {
  final String message;
  SessionExpiredStateAuth(this.message);
}

// Common Server Failure State
class CommonServerFailure extends AuthFlowState {
  final String error;
  CommonServerFailure(this.error);
}

// Check Network Connection State
class CheckNetworkConnectionAuthFlow extends AuthFlowState {}
