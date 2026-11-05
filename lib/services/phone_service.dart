import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class PhoneService {
  /// Open a common app by name
  static Future<bool> openApp(String appName) async {
    final lower = appName.toLowerCase().trim();

    // Common package names
    final Map<String, String> packages = {
      'youtube': 'com.google.android.youtube',
      'chrome': 'com.android.chrome',
      'google': 'com.google.android.googlequicksearchbox',
      'gmail': 'com.google.android.gm',
      'maps': 'com.google.android.apps.maps',
      'whatsapp': 'com.whatsapp',
      'instagram': 'com.instagram.android',
      'facebook': 'com.facebook.katana',
      'twitter': 'com.twitter.android',
      'x': 'com.twitter.android',
      'tiktok': 'com.zhiliaoapp.musically',
      'spotify': 'com.spotify.music',
      'settings': 'com.android.settings',
      'camera': 'com.android.camera',
      'photos': 'com.google.android.apps.photos',
      'messages': 'com.google.android.apps.messaging',
      'phone': 'com.android.dialer',
      'contacts': 'com.android.contacts',
      'clock': 'com.google.android.deskclock',
      'calculator': 'com.google.android.calculator',
      'play store': 'com.android.vending',
      'playstore': 'com.android.vending',
    };

    String? package = packages[lower];

    // Fuzzy match
    if (package == null) {
      for (final entry in packages.entries) {
        if (lower.contains(entry.key) || entry.key.contains(lower)) {
          package = entry.value;
          break;
        }
      }
    }

    if (package != null) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: package,
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
        return true;
      } catch (e) {
        debugPrint('Failed to open $package: $e');
      }
    }

    // Fallback: try searching the app name
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'market://search?q=$appName',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return true;
    } catch (e) {
      debugPrint('Fallback failed: $e');
      return false;
    }
  }

  /// Set an alarm (basic - opens clock app with action)
  static Future<bool> setAlarm({int? hour, int? minute, String? message}) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.SET_ALARM',
        arguments: {
          if (hour != null) 'android.intent.extra.alarm.HOUR': hour,
          if (minute != null) 'android.intent.extra.alarm.MINUTES': minute,
          if (message != null) 'android.intent.extra.alarm.MESSAGE': message,
          'android.intent.extra.alarm.SKIP_UI': false,
        },
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return true;
    } catch (e) {
      debugPrint('Set alarm failed: $e');
      // Fallback: just open clock
      return await openApp('clock');
    }
  }

  /// Open notes / create note (uses a simple web note or keep)
  static Future<bool> takeNote(String content) async {
    try {
      // Try Google Keep
      final intent = AndroidIntent(
        action: 'android.intent.action.SEND',
        type: 'text/plain',
        package: 'com.google.android.keep',
        arguments: {
          'android.intent.extra.TEXT': content,
        },
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return true;
    } catch (e) {
      // Fallback to share sheet
      try {
        final uri = Uri.parse('https://keep.google.com');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  /// Open a URL
  static Future<bool> openUrl(String url) async {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('Open URL failed: $e');
    }
    return false;
  }
}
