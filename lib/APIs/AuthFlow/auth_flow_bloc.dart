import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:divine_arc/Utils/app_imports.dart';
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

          print('Facebook Name: $name');
          print('Facebook Email: $email');
          print('Facebook Picture: $profileImage');
          print('Facebook ID: $id');
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
        emit(CheckNetworkConnectionAuthFlow());
        print("No internet connection.");
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

      print("Signup API Request URL: $requestUrl");
      print("Signup API Request Body: ${jsonEncode(requestBody)}");

      try {
        final response = await http.post(
          requestUrl,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestBody),
        );

        print("Signup API Response Body: ${response.body}");

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 201) {
          emit(SignUpSuccess(responseData));
        } else if (response.statusCode == 401) {
          emit(SessionExpiredStateAuth('Session expired. Please login again.'));
        } else {
          emit(SignUpFailure(responseData));
        }
      } catch (e) {
        emit(CommonServerFailure(e.toString()));
        print("Exception occurred: $e");
      }
    });

    // Login Bloc
    on<LoginEventHandler>((event, emit) async {
      if (!await ConnectivityService.isConnected()) {
        emit(CheckNetworkConnectionAuthFlow());
        print("No internet connection.");
        return;
      }

      emit(LoginLoading());

      final requestUrl = Uri.parse(APIEndPoints.login);
      final Map<String, dynamic> requestBody = {
        "email": event.email,
        "password": event.password,
      };

      print("Login API Request URL: $requestUrl");
      print("Login API Request Body: ${jsonEncode(requestBody)}");

      try {
        final response = await http.post(
          requestUrl,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestBody),
        );

        print("Login API Response Status Code: ${response.statusCode}");
        print("Login API Response Body: ${response.body}");

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
            print("Extracted Cookie Token: $authCookie");
            PrefUtils.setToken(authCookie);
          }
        } else {
          print("Set-Cookie header not found.");
        }

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          emit(LoginSuccess(responseData));
        } else if (response.statusCode == 401) {
          emit(SessionExpiredStateAuth('Session expired. Please login again.'));
        } else {
          emit(LoginFailure(responseData['message']));
        }
      } catch (e) {
        emit(CommonServerFailure(e.toString()));
        print("Exception occurred: $e");
      }
    });

    // Forgot Password Bloc
    on<ForgotPasswordEventHandler>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(ForgotPasswordLoading());

        final Uri requestUrl = Uri.parse(APIEndPoints.forgotPassword);

        final Map<String, dynamic> requestBody = {"email": event.email};
        print("🔵 Request URL: $requestUrl");
        print(
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

          print("🟣 Response Status Code: ${response.statusCode}");
          print("🟤 Raw Response Body: ${response.body}");

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            emit(ForgotPasswordSuccess(responseData));
            print("✅ Parsed Response Data: $responseData");
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateAuth('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(ForgotPasswordFailure(errorData));
            print("❌ Error Response Data: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionAuthFlow());
          print("❗ SocketException: No internet connection.");
        } catch (e) {
          emit(CommonServerFailure('An error occurred: $e'));
          print("❗ Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionAuthFlow());
        print("❗ No internet connection.");
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
        print("🔵 Request URL: $requestUrl");
        print(
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

          print("🟣 Response Status Code: ${response.statusCode}");
          print("🟤 Raw Response Body: ${response.body}");

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            emit(ChangePasswordSuccess(responseData));
            print("✅ Parsed Response Data: $responseData");
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateAuth('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(ChangePasswordFailure(errorData));
            print("❌ Error Response Data: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionAuthFlow());
          print("❗ SocketException: No internet connection.");
        } catch (e) {
          emit(CommonServerFailure('An error occurred: $e'));
          print("❗ Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionAuthFlow());
        print("❗ No internet connection.");
      }
    });

    on<SocialLoginEventHandler>((event, emit) async {
      if (!await ConnectivityService.isConnected()) {
        emit(CheckNetworkConnectionAuthFlow());
        print("No internet connection.");
        return;
      }

      emit(SocialLoginLoading());

      final requestUrl = Uri.parse(APIEndPoints.socialLogin);
      final Map<String, dynamic> requestBody = {
        "email": event.email,
        "name": event.name,
        "social_id": event.socialId,
        "social_type": event.socialType,
      };

      print("Login API Request URL: $requestUrl");
      print("Login API Request Body: ${jsonEncode(requestBody)}");

      try {
        final response = await http.post(
          requestUrl,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestBody),
        );

        print("Social Login API Response Status Code: ${response.statusCode}");
        print("Social Login API Response Body: ${response.body}");

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
            print("Extracted Cookie Token: $authCookie");
            PrefUtils.setToken(authCookie);
          }
        } else {
          print("Set-Cookie header not found.");
        }

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          emit(SocialLoginSuccess(responseData));
        } else if (response.statusCode == 401) {
          emit(SessionExpiredStateAuth('Session expired. Please login again.'));
        } else {
          emit(SocialLoginFailure(responseData['message']));
        }
      } catch (e) {
        emit(CommonServerFailure(e.toString()));
        print("Exception occurred: $e");
      }
    });

    on<SendDeviceTokenEvent>((event, emit) async {
      // 1️⃣ Check internet
      final bool isConnected = await ConnectivityService.isConnected();
      if (!isConnected) {
        emit(CheckNetworkConnectionAuthFlow());
        debugPrint("❌ No internet connection");
        return;
      }

      emit(DeviceTokenSending());

      try {
        final Uri requestUrl = Uri.parse(APIEndPoints.sendDeviceToken);

        /// ✅ Build request body safely
        final Map<String, dynamic> requestBody = {
          "device-token": event.deviceToken,
        };

        /// ✅ Add userId only if valid
        if (event.userID != null && event.userID!.trim().isNotEmpty) {
          requestBody["userId"] = event.userID;
        }

        debugPrint("➡️ Request URL: $requestUrl");
        debugPrint("➡️ Request Body: $requestBody");

        final response = await http
            .post(
              requestUrl,
              headers: const {
                "Content-Type": "application/json",
                "Accept": "application/json",
              },
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 15));

        debugPrint("✅ Status Code: ${response.statusCode}");
        debugPrint("✅ Response Body: ${response.body}");

        Map<String, dynamic> responseData = {};
        try {
          responseData = jsonDecode(response.body);
        } catch (_) {
          debugPrint("⚠️ Response is not valid JSON");
        }

        if (response.statusCode == 200) {
          emit(DeviceTokenSentSuccess(responseData));
        } else if (response.statusCode == 401) {
          emit(
            SessionExpiredStateAuth(
              responseData['message'] ?? 'Session expired. Please login again.',
            ),
          );
        } else {
          emit(
            DeviceTokenSendFailure(
              responseData['message'] ?? 'Something went wrong',
            ),
          );
        }
      } catch (e, stackTrace) {
        debugPrint("🔥 Exception: $e");
        debugPrint("📌 StackTrace: $stackTrace");
        emit(CommonServerFailure(e.toString()));
      }
    });
  }
}
