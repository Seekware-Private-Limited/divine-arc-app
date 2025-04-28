import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal();

  // Stream that broadcasts the current connectivity status
  final _connectivityStreamController = StreamController<ConnectivityResult>();
  Stream<ConnectivityResult> get connectivityStream =>
      _connectivityStreamController.stream;

  // Initialize the connectivity monitoring
  void initialize() {
    Connectivity().onConnectivityChanged.listen((result) {
      _connectivityStreamController.add(result as ConnectivityResult);
    });
  }

  // Check if the device is currently connected to the internet
  static Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Dispose of the stream controller when it's no longer needed
  void dispose() {
    _connectivityStreamController.close();
  }
}