import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

class VibrationService {
  /// Check if the device has a vibrator
  static Future<bool> hasVibrator() async {
    return await Vibration.hasVibrator() ?? false;
  }

  /// Single short vibration (useful for regular events like button clicks or question answering)
  static Future<void> vibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  /// Double vibration (good for starting a stage or finishing)
  static Future<void> doubleVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 100, 50, 100]);
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  /// Long vibration (good for finishing a task or game)
  static Future<void> longVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500);
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  /// Light vibration (for subtle feedback)
  static Future<void> lightVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  /// Error vibration (triple vibration)
  static Future<void> errorVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]);
    } else {
      HapticFeedback.vibrate();
    }
  }
}
