import 'package:divine_arc/Utils/shared_preference.dart';
import 'dart:convert'; // Import for JSON encoding/decoding

class PrefUtils {
  static setToken(String value) {
    Prefs.prefs?.setString(SharedPrefsKeys.token, value);
  }

  static String getToken() {
    final String? value = Prefs.prefs?.getString(SharedPrefsKeys.token);
    return value ?? '';
  }

  static setName(String value) {
    Prefs.prefs?.setString(SharedPrefsKeys.name, value);
  }

  static String getName() {
    final String? value = Prefs.prefs?.getString(SharedPrefsKeys.name);
    return value ?? '';
  }

  static setProfilePicture(String value) {
    Prefs.prefs?.setString(SharedPrefsKeys.profilePicture, value);
  }

  static String getProfilePicture() {
    final String? value = Prefs.prefs?.getString(
      SharedPrefsKeys.profilePicture,
    );
    return value ?? '';
  }

  static setEmail(String value) {
    Prefs.prefs?.setString(SharedPrefsKeys.email, value);
  }

  static String getEmail() {
    final String? value = Prefs.prefs?.getString(SharedPrefsKeys.email);
    return value ?? '';
  }

  static setLanguage(String value) {
    Prefs.prefs?.setString(SharedPrefsKeys.lang, value);
  }

  static String getLanguage() {
    final String? value = Prefs.prefs?.getString(SharedPrefsKeys.lang);
    return value ?? '';
  }

  static setSessionID(String value) {
    Prefs.prefs?.setString(SharedPrefsKeys.sessionID, value);
  }

  static String getSessionID() {
    final String? value = Prefs.prefs?.getString(SharedPrefsKeys.sessionID);
    return value ?? '';
  }

  static setChatID(String value) {
    Prefs.prefs?.setString(SharedPrefsKeys.ChatID, value);
  }

  static String getChatID() {
    final String? value = Prefs.prefs?.getString(SharedPrefsKeys.ChatID);
    return value ?? '';
  }

  static void setOnboardingVisible(bool value) {
    Prefs.prefs?.setBool(SharedPrefsKeys.onboardingVisible, value);
  }

  static bool getOnboardingVisible() {
    final bool? value = Prefs.prefs?.getBool(SharedPrefsKeys.onboardingVisible);
    return value ?? false;
  }

  static void setIsSocialLogin(bool value) {
    Prefs.prefs?.setBool(SharedPrefsKeys.isSocialLogin, value);
  }

  static bool getIsSocialLogin() {
    final bool? value = Prefs.prefs?.getBool(SharedPrefsKeys.isSocialLogin);
    return value ?? false;
  }

  static void setIsGuest(bool value) {
    Prefs.prefs?.setBool(SharedPrefsKeys.isGuest, value);
  }

  static bool getIsGuest() {
    final bool? value = Prefs.prefs?.getBool(SharedPrefsKeys.isGuest);
    return value ?? false;
  }

  static void setIsLogin(bool value) {
    Prefs.prefs?.setBool(SharedPrefsKeys.isLogin, value);
  }

  static bool getIsLogin() {
    final bool? value = Prefs.prefs?.getBool(SharedPrefsKeys.isLogin);
    return value ?? false;
  }

  static void setUnreadNotificationCount(int value) {
    Prefs.prefs?.setInt(SharedPrefsKeys.unreadNotificationCount, value);
  }

  static int getUnreadNotificationCount() {
    final int? value = Prefs.prefs?.getInt(
      SharedPrefsKeys.unreadNotificationCount,
    );
    return value ?? 0;
  }

  // New method to save chatHistory
  static void setChatHistory(List<Map<String, dynamic>> chatHistory) {
    final String chatHistoryJson = jsonEncode(chatHistory);
    Prefs.prefs?.setString(SharedPrefsKeys.chatHistory, chatHistoryJson);
  }

  // New method to retrieve chatHistory
  static List<Map<String, dynamic>> getChatHistory() {
    final String? chatHistoryJson = Prefs.prefs?.getString(
      SharedPrefsKeys.chatHistory,
    );
    if (chatHistoryJson != null && chatHistoryJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(chatHistoryJson);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    return [];
  }

  static void clearAll() {
    Prefs.prefs?.clear();
  }
}

class SharedPrefsKeys {
  static const token = 'token';
  static const name = 'name';
  static const profilePicture = 'profilePicture';
  static const email = 'email';
  static const lang = 'lang';
  static const sessionID = 'sessionID';
  static const onboardingVisible = 'onboardingVisible';
  static const isLogin = 'isLogin';
  static const ChatID = 'ChatID';
  static const isGuest = 'isGuest';
  static const isSocialLogin = 'isSocialLogin';
  static const unreadNotificationCount = 'unreadNotificationCount';
  static const chatHistory = 'chatHistory';
}
