import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = Locale('en'); // Default language is English

  Locale get locale => _locale;

  // Method to change language
  void changeLanguage(String languageCode) {
    _locale = Locale(languageCode);
    notifyListeners();  // Notify listeners to rebuild widgets with the new language
  }
}
