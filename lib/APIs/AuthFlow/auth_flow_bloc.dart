import 'package:gita_gpt/Utils/api_constant.dart';
import 'package:gita_gpt/Utils/app_imports.dart';
import 'package:gita_gpt/Utils/connectivity_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
part 'auth_flow_event.dart';
part 'auth_flow_state.dart';

class AuthFlowBloc extends Bloc<AuthFlowEvent, AuthFlowState> {
  AuthFlowBloc() : super(AuthFlowInitial()) {

    // Google Login Bloc
    on<GoogleLoginEventHandler>((event, emit) async {
      if (!await ConnectivityService.isConnected()) {
        emit(CheckNetworkConnection());
        developer.log("No internet connection.");
        return;
      }

      emit(GoogleLoginLoading());

      final requestUrl = Uri.parse(
        APIEndPoints.googleLogin,
      ); // Replace with actual URL

      developer.log("Google Login API Request URL: $requestUrl");

      try {
        final response = await http.get(
          requestUrl,
          headers: {"Content-Type": "application/json"},
        );

        developer.log("Google Login API Response Body: ${response.body}");

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          final url = responseData['url'];
          emit(GoogleLoginSuccess(url));
        } else {
          emit(GoogleLoginFailure(responseData['message']));
        }
      } catch (e) {
        emit(CommonServerFailure(e.toString()));
        developer.log("Exception occurred: $e");
      }
    });

    // Facebook Login Bloc
    on<FacebookLoginEventHandler>((event, emit) async {
      emit(FacebookLoginLoading());
      try {
        final LoginResult result = await FacebookAuth.instance.login();

        if (result.status == LoginStatus.success) {
          final userData = await FacebookAuth.instance.getUserData();

          final String name = userData['name'] ?? '';
          final String email = userData['email'] ?? '';
          final String profileImage = userData['picture']['data']['url'] ?? '';
          final String id = userData['id'] ?? '';

          emit(FacebookLoginSuccess(name, email, profileImage, id));

          developer.log('Facebook Name: $name');
          developer.log('Facebook Email: $email');
          developer.log('Facebook Picture: $profileImage');
          developer.log('Facebook ID: $id');
        } else {
          emit(FacebookLoginFailure(result.message ?? 'Login failed'));
        }
      } catch (e) {
        if (kDebugMode) {
          print("Facebook login error: $e");
        }
        emit(FacebookLoginFailure(e.toString()));
      }
    });

    // SignUp Bloc
    on<SignupEventHandler>((event, emit) async {
      if (!await ConnectivityService.isConnected()) {
        emit(CheckNetworkConnection());
        developer.log("No internet connection.");
        return;
      }

      emit(SignUpLoading());

      final requestUrl = Uri.parse(
        APIEndPoints.signup,
      ); // Replace with actual URL

      final Map<String, dynamic> requestBody = {
        "name": event.name,
        "email": event.email,
        "password": event.password,
      };

      developer.log("Signup API Request URL: $requestUrl");
      developer.log("Signup API Request Body: ${jsonEncode(requestBody)}");

      try {
        final response = await http.post(
          requestUrl,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestBody),
        );

        developer.log("Signup API Response Body: ${response.body}");

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 201) {
          emit(SignUpSuccess(responseData));
        } else {
          emit(SignUpFailure(responseData));
        }
      } catch (e) {
        emit(CommonServerFailure(e.toString()));
        developer.log("Exception occurred: $e");
      }
    });

    // Login Bloc
    on<LoginEventHandler>((event, emit) async {
      if (!await ConnectivityService.isConnected()) {
        emit(CheckNetworkConnection());
        developer.log("No internet connection.");
        return;
      }

      emit(LoginLoading());

      final requestUrl = Uri.parse(APIEndPoints.login);
      final Map<String, dynamic> requestBody = {
        "email": event.email,
        "password": event.password,
      };

      developer.log("Login API Request URL: $requestUrl");
      developer.log("Login API Request Body: ${jsonEncode(requestBody)}");

      try {
        final response = await http.post(
          requestUrl,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestBody),
        );

        developer.log("Login API Response Status Code: ${response.statusCode}");
        developer.log("Login API Response Body: ${response.body}");

        // ✅ Extract Set-Cookie token
        final setCookieHeader = response.headers['set-cookie'];
        if (setCookieHeader != null) {
          final authCookie = setCookieHeader
              .split(';')
              .firstWhere((c) => c.contains('Authorization='),
              orElse: () => '');

          if (authCookie.isNotEmpty) {
            developer.log("Extracted Cookie Token: $authCookie");
            PrefUtils.setToken(authCookie);
          }
        } else {
          developer.log("Set-Cookie header not found.");
        }

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          emit(LoginSuccess(responseData));
        } else {
          emit(LoginFailure(responseData['message']));
        }
      } catch (e) {
        emit(CommonServerFailure(e.toString()));
        developer.log("Exception occurred: $e");
      }
    });

  }

}
