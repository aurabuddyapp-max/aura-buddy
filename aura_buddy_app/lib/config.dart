import 'package:flutter/foundation.dart';

class Config {
  // If we're building for release (e.g. `flutter build web` or `flutter build apk`), use Render.
  // Otherwise, use local development URLs.
  
  static String get apiBaseUrl {
    if (kReleaseMode) {
      // Production backend URL (Render)
      return 'https://aura-buddy-api.onrender.com';
    } else {
      // Local development URL
      // Use 10.0.2.2 for Android emulator, 127.0.0.1 for iOS simulator / web
      if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
        return 'http://10.0.2.2:8000';
      }
      return 'http://127.0.0.1:8000';
    }
  }
}
