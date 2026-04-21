import 'package:flutter/material.dart';

class LocalizationHelper {
  /// Check if the current locale is RTL (Right-to-Left)
  static bool isRTL(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar';
  }

  /// Get text direction based on locale
  static TextDirection getTextDirection(BuildContext context) {
    return isRTL(context) ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Get alignment based on locale (for RTL support)
  static Alignment getAlignment(BuildContext context, {bool isStart = true}) {
    final isRtl = isRTL(context);
    if (isStart) {
      return isRtl ? Alignment.centerRight : Alignment.centerLeft;
    } else {
      return isRtl ? Alignment.centerLeft : Alignment.centerRight;
    }
  }

  /// Get text align based on locale
  static TextAlign getTextAlign(BuildContext context, {bool isStart = true}) {
    final isRtl = isRTL(context);
    if (isStart) {
      return isRtl ? TextAlign.right : TextAlign.left;
    } else {
      return isRtl ? TextAlign.left : TextAlign.right;
    }
  }

  /// Get edge insets with RTL support
  static EdgeInsets getEdgeInsets(
    BuildContext context, {
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    final isRtl = isRTL(context);
    if (isRtl) {
      return EdgeInsets.only(
        left: right,
        top: top,
        right: left,
        bottom: bottom,
      );
    }
    return EdgeInsets.only(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  /// Format date based on locale
  static String formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;

    switch (locale) {
      case 'ar':
        // Arabic date format: DD/MM/YYYY
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      case 'fr':
        // French date format: DD/MM/YYYY
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      default:
        // English date format: MM/DD/YYYY
        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  /// Format time based on locale
  static String formatTime(BuildContext context, DateTime time) {
    final locale = Localizations.localeOf(context).languageCode;
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');

    switch (locale) {
      case 'ar':
        // Arabic uses 12-hour format with Arabic AM/PM
        final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        final period = hour >= 12 ? 'م' : 'ص'; // م = PM, ص = AM
        return '$hour12:$minute $period';
      case 'fr':
        // French uses 24-hour format
        return '${hour.toString().padLeft(2, '0')}:$minute';
      default:
        // English uses 12-hour format
        final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        final period = hour >= 12 ? 'PM' : 'AM';
        return '$hour12:$minute $period';
    }
  }

  /// Format currency based on locale
  static String formatCurrency(BuildContext context, double amount) {
    final locale = Localizations.localeOf(context).languageCode;

    switch (locale) {
      case 'ar':
        // Arabic: amount followed by currency symbol
        return '${amount.toStringAsFixed(2)} \$';
      case 'fr':
        // French: amount followed by currency symbol with space
        return '${amount.toStringAsFixed(2)} \$';
      default:
        // English: currency symbol followed by amount
        return '\$${amount.toStringAsFixed(2)}';
    }
  }

  /// Get month name based on locale
  static String getMonthName(BuildContext context, int month) {
    final locale = Localizations.localeOf(context).languageCode;

    final monthNames = {
      'en': ['January', 'February', 'March', 'April', 'May', 'June',
             'July', 'August', 'September', 'October', 'November', 'December'],
      'ar': ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
             'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'],
      'fr': ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
             'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'],
    };

    return monthNames[locale]?[month - 1] ?? monthNames['en']![month - 1];
  }

  /// Get day name based on locale
  static String getDayName(BuildContext context, int day) {
    final locale = Localizations.localeOf(context).languageCode;

    final dayNames = {
      'en': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
      'ar': ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
      'fr': ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'],
    };

    return dayNames[locale]?[day - 1] ?? dayNames['en']![day - 1];
  }

  /// Format number based on locale
  static String formatNumber(BuildContext context, int number) {
    final locale = Localizations.localeOf(context).languageCode;

    if (locale == 'ar') {
      // Convert to Arabic-Indic numerals
      const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      return number.toString().split('').map((digit) {
        final index = int.tryParse(digit);
        return index != null ? arabicNumerals[index] : digit;
      }).join();
    }

    return number.toString();
  }
}
