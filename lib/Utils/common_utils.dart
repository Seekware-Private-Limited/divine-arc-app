import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CommonUtils {
  /// Show a toast message with optional customization
  static void showToast(String message,
      {ToastGravity gravity = ToastGravity.BOTTOM,
        Color backgroundColor = Colors.red,
        Color textColor = Colors.white,
        Toast toastLength = Toast.LENGTH_LONG}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: gravity,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }
}
