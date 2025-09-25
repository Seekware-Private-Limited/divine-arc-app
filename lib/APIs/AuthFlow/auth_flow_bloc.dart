import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:gita_gpt/Utils/app_imports.dart';
part 'auth_flow_event.dart';
part 'auth_flow_state.dart';

class AuthFlowBloc extends Bloc<AuthFlowEvent, AuthFlowState> {
  AuthFlowBloc() : super(AuthFlowInitial()) {
    // Google Login Bloc
    on<GoogleLoginEventHandler>((event, emit) async {
      emit(GoogleLoginLoading());

      var googleSignIn = GoogleSignIn();
      GoogleSignInAccount? googleSignInAccount;
      try {
        await googleSignIn.signOut();
        googleSignInAccount = await googleSignIn.signIn();

        if (googleSignInAccount != null) {
          emit(
            GoogleLoginSuccess(
              googleSignInAccount.displayName.toString(),
              googleSignInAccount.email,
              googleSignInAccount.photoUrl.toString(),
              googleSignInAccount.id.toString(),
            ),
          );
          print('User Name Is : ${googleSignInAccount.displayName}');
          print('User Email Is : ${googleSignInAccount.email}');
          print('User Photo Is : ${googleSignInAccount.photoUrl}');
          print('User Id Is : ${googleSignInAccount.id}');
        } else {
          emit(
            GoogleLoginFailure("Something went wrong.Please try again later."),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          emit(GoogleLoginFailure(e.toString()));
          print(e.toString());
        }
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
              .firstWhere(
                (c) => c.contains('Authorization='),
                orElse: () => '',
              );

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

    // Forgot Password Bloc
    on<ForgotPasswordEventHandler>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(ForgotPasswordLoading());

        final Uri requestUrl = Uri.parse(APIEndPoints.forgotPassword);

        final Map<String, dynamic> requestBody = {"email": event.email};
        developer.log("🔵 Request URL: $requestUrl");
        developer.log(
          "🟡 Request Headers: ${{'accept': 'application/json', 'Content-Type': 'application/json', 'Cookie': PrefUtils.getToken()}}",
        );

        try {
          final response = await http.post(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
            body: jsonEncode(requestBody),
          );

          developer.log("🟣 Response Status Code: ${response.statusCode}");
          developer.log("🟤 Raw Response Body: ${response.body}");

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            emit(ForgotPasswordSuccess(responseData));
            developer.log("✅ Parsed Response Data: $responseData");
          } else {
            final errorData = jsonDecode(response.body);
            emit(ForgotPasswordFailure(errorData));
            developer.log("❌ Error Response Data: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnection());
          developer.log("❗ SocketException: No internet connection.");
        } catch (e) {
          emit(CommonServerFailure('An error occurred: $e'));
          developer.log("❗ Exception: $e");
        }
      } else {
        emit(CheckNetworkConnection());
        developer.log("❗ No internet connection.");
      }
    });

    // Change Password Bloc
    on<ChangePasswordEventHandler>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(ChangePasswordLoading());

        final Uri requestUrl = Uri.parse(APIEndPoints.updatePassword);

        final Map<String, dynamic> requestBody = {
          "currentPassword": event.currentPassword,
          "newPassword": event.newPassword,
        };
        developer.log("🔵 Request URL: $requestUrl");
        developer.log(
          "🟡 Request Headers: ${{'accept': 'application/json', 'Content-Type': 'application/json', 'Cookie': PrefUtils.getToken()}}",
        );

        try {
          final response = await http.post(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
            body: jsonEncode(requestBody),
          );

          developer.log("🟣 Response Status Code: ${response.statusCode}");
          developer.log("🟤 Raw Response Body: ${response.body}");

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            emit(ChangePasswordSuccess(responseData));
            developer.log("✅ Parsed Response Data: $responseData");
          } else {
            final errorData = jsonDecode(response.body);
            emit(ChangePasswordFailure(errorData));
            developer.log("❌ Error Response Data: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnection());
          developer.log("❗ SocketException: No internet connection.");
        } catch (e) {
          emit(CommonServerFailure('An error occurred: $e'));
          developer.log("❗ Exception: $e");
        }
      } else {
        emit(CheckNetworkConnection());
        developer.log("❗ No internet connection.");
      }
    });

    on<SocialLoginEventHandler>((event, emit) async {
      if (!await ConnectivityService.isConnected()) {
        emit(CheckNetworkConnection());
        developer.log("No internet connection.");
        return;
      }

      emit(SocialLoginLoading());

      final requestUrl = Uri.parse(APIEndPoints.socialLogin);
      final Map<String, dynamic> requestBody = {
        "email": event.email,
        "social_id": event.socialId,
        "social_type": event.socialType,
      };

      developer.log("Login API Request URL: $requestUrl");
      developer.log("Login API Request Body: ${jsonEncode(requestBody)}");

      try {
        final response = await http.post(
          requestUrl,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestBody),
        );

        developer.log(
          "Social Login API Response Status Code: ${response.statusCode}",
        );
        developer.log("Social Login API Response Body: ${response.body}");

        // ✅ Extract Set-Cookie token
        final setCookieHeader = response.headers['set-cookie'];
        if (setCookieHeader != null) {
          final authCookie = setCookieHeader
              .split(';')
              .firstWhere(
                (c) => c.contains('Authorization='),
                orElse: () => '',
              );

          if (authCookie.isNotEmpty) {
            developer.log("Extracted Cookie Token: $authCookie");
            PrefUtils.setToken(authCookie);
          }
        } else {
          developer.log("Set-Cookie header not found.");
        }

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          emit(SocialLoginSuccess(responseData));
        } else {
          emit(SocialLoginFailure(responseData['message']));
        }
      } catch (e) {
        emit(CommonServerFailure(e.toString()));
        developer.log("Exception occurred: $e");
      }
    });
  }
}
