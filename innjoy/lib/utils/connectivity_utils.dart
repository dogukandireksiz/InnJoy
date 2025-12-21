import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// A utility class to check internet connectivity across the app.
class ConnectivityUtils {
  static final Connectivity _connectivity = Connectivity();

  /// Checks if the device has an active internet connection.
  /// Returns true if connected (wifi, mobile, ethernet), false otherwise.
  static Future<bool> hasConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((status) =>
        status == ConnectivityResult.wifi ||
        status == ConnectivityResult.mobile ||
        status == ConnectivityResult.ethernet);
  }

  /// Shows a "No Internet" snackbar and returns false if offline.
  /// Use this before critical operations.
  static Future<bool> checkAndShowSnackbar(BuildContext context) async {
    final hasInternet = await hasConnection();
    if (!hasInternet && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 12),
              Text('No internet connection. Please try again.'),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
    return hasInternet;
  }

  /// Stream that emits connectivity changes.
  /// Use this for reactive connectivity monitoring.
  static Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}








