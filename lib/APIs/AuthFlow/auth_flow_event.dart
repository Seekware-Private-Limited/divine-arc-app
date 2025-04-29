part of 'auth_flow_bloc.dart';

@immutable
sealed class AuthFlowEvent {}

// Google Login Event
class GoogleLoginEventHandler extends AuthFlowEvent {}

// Apple Login Event
class AppleLoginEventHandler extends AuthFlowEvent {}
