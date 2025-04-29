import 'package:gita_gpt/Utils/app_imports.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:developer' as developer;
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
          emit(GoogleLoginSuccess(
            googleSignInAccount.displayName.toString(),
            googleSignInAccount.email,
            googleSignInAccount.photoUrl.toString(),
            googleSignInAccount.id.toString(),
          ));
          developer.log('User Name Is : ${googleSignInAccount.displayName}');
          developer.log('User Email Is : ${googleSignInAccount.email}');
          developer.log('User Photo Is : ${googleSignInAccount.photoUrl}');
          developer.log('User Id Is : ${googleSignInAccount.id}');
        } else {
          emit(GoogleLoginFailure(""));
        }
      } catch (e) {
        if (kDebugMode) {
          emit(GoogleLoginFailure(e.toString()));
          print(e.toString());
        }
      }
    });

    // Apple Login Bloc
    on<AppleLoginEventHandler>((event, emit) async {
      try {
        emit(AppleLoginLoading());
        final rawNonce = generateNonce();
        final nonce = sha256ofString(rawNonce);

        // Request credential for the currently signed-in Apple account.
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );

        // Create OAuthCredential from the credential returned by Apple.
        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
          rawNonce: rawNonce,
        );


        // Sign in to Firebase with the Apple credential.
        final jsonResponse = await FirebaseAuth.instance.signInWithCredential(
          oauthCredential,
        );

        final user = jsonResponse.user;

        // Handle first-time sign-in or if email is provided
        String? email = user?.email ??
            appleCredential.email; // Prefer Firebase email if available
        String? displayName = user?.displayName ?? appleCredential.givenName ??
            appleCredential.familyName;

        email ??= "Unknown";

        if (user != null) {
          emit(AppleLoginSuccess(
            displayName ?? "",
            email,
            user.photoURL ?? "",
            user.uid,
          ));
        } else {
          emit(AppleLoginError(const {"error": "User authentication failed"}));
        }
      } catch (e) {
        // Handle errors during sign-in
        Map<String, dynamic> errorDetails = {
          "error": e.toString(),
          "stackTrace": e is Error ? e.stackTrace.toString() : null,
        };

        if (kDebugMode) {
          print("Apple Login Error: $errorDetails");
        }

        emit(AppleLoginError(errorDetails));
      }
    });
  }
  // Helper methods for generating nonce and SHA256 hash.
  String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
