import 'package:gita_gpt/Utils/shared_preference.dart';

class PrefUtils {
  static void setToken(String value) {
    Prefs.prefs?.setString(SharedPrefsKeys.token, value);
  }

  static String getToken() {
    final String? value = Prefs.prefs?.getString(SharedPrefsKeys.token);
    return value ?? '';
  }

  static void setUnreadNotificationCount(int value) {
    Prefs.prefs?.setInt(SharedPrefsKeys.unreadNotificationCount, value);
  }

  static int getUnreadNotificationCount() {
    final int? value = Prefs.prefs?.getInt(SharedPrefsKeys.unreadNotificationCount);
    return value ?? 0; // Default to 0 if no value is stored
  }

}

class SharedPrefsKeys {
  static const token = 'token';
  static const unreadNotificationCount = 'unreadNotificationCount';
}
