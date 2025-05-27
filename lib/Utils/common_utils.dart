import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CommonUtils {

  // Error Toast
  static void showErrorToast(String message) {
    Fluttertoast.showToast(
      backgroundColor: Colors.red,
      textColor: Colors.white,
      gravity: ToastGravity.BOTTOM,
      msg: message,
    );
  }

  // Success Toast
  static void showSuccessToast(String message) {
    Fluttertoast.showToast(
      backgroundColor: Colors.green,
      textColor: Colors.white,
      gravity: ToastGravity.BOTTOM,
      msg: message,
    );
  }

  // Custom Toast
  static void showCustomToast(String message,
      {ToastGravity gravity = ToastGravity.BOTTOM,
        Color backgroundColor = Colors.green,
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
