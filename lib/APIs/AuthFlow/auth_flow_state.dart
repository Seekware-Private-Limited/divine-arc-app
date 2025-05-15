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


// Apple Login States
class AppleLoginLoading extends AuthFlowState {}

class AppleLoginSuccess extends AuthFlowState {
  final String name;
  final String email;
  final String image;
  final String id;
  AppleLoginSuccess(this.name, this.email, this.image, this.id);
}

class AppleLoginError extends AuthFlowState {
  final Map<String,dynamic>  errorMessage;
  AppleLoginError(this.errorMessage);
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




