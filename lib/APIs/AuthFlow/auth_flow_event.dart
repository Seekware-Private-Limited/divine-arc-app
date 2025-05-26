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
  SignupEventHandler({required this.name,required this.email,required this.password});
}

// Login Event
class LoginEventHandler extends AuthFlowEvent {
  final String email;
  final String password;
  LoginEventHandler({required this.email,required this.password});
}