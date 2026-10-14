import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  /// Returns the base URL for the backend depending on platform.
  /// - Android Emulator requires 10.0.2.2 to connect to host localhost:8000
  /// - iOS Simulator / Desktop / Web uses 127.0.0.1:8000
  /// - Real physical devices should use your PC's LAN IP (e.g. 192.168.1.X)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  // Auth endpoints
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String registerEndpoint = '/api/v1/auth/register';
}
