import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'haptics_stub.dart'
    if (dart.library.js_interop) 'haptics_web.dart' as browser_haptics;

/// Uses Flutter's native haptics on mobile and the browser vibration API on web.
class AppHaptics {
  static const String _preferenceKey = 'app_haptics_enabled';
  static final ValueNotifier<bool> isEnabled = ValueNotifier<bool>(true);

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    isEnabled.value = preferences.getBool(_preferenceKey) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    isEnabled.value = enabled;
    if (enabled) mediumImpact();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_preferenceKey, enabled);
  }

  static void lightImpact() {
    if (!isEnabled.value) return;
    if (kIsWeb) {
      browser_haptics.lightImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  static void mediumImpact() {
    if (!isEnabled.value) return;
    if (kIsWeb) {
      browser_haptics.mediumImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  static void heavyImpact() {
    if (!isEnabled.value) return;
    if (kIsWeb) {
      browser_haptics.heavyImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }
}
