import 'package:gita_gpt/Utils/shared_preference.dart';

class PrefUtils {
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

  static void setOnboardingVisible(bool value) {
    Prefs.prefs?.setBool(SharedPrefsKeys.onboardingVisible, value);
  }

  static bool getOnboardingVisible() {
    final bool? value = Prefs.prefs?.getBool(SharedPrefsKeys.onboardingVisible);
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
    return value ?? 0; // Default to 0 if no value is stored
  }
}

class SharedPrefsKeys {
  static const lang = 'lang';
  static const sessionID = 'sessionID';
  static const onboardingVisible = 'onboardingVisible';
  static const isLogin = 'isLogin';
  static const unreadNotificationCount = 'unreadNotificationCount';
}
