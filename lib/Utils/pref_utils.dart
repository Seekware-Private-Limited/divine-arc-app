import 'package:gita_gpt/Utils/shared_preference.dart';

class PrefUtils {
  static setLanguage(String value) {
    Prefs.prefs?.setString(SharedPrefsKeys.lang, value);
  }

  static String getLanguage() {
    final String? value = Prefs.prefs?.getString(SharedPrefsKeys.lang);
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
  static const lang = 'lang';
  static const unreadNotificationCount = 'unreadNotificationCount';
}
