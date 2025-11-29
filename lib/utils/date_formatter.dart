import 'package:intl/intl.dart';

class DateFormatter {
  /// Format date to Indonesian format: "19 November 2025"
  static String toIndonesian(DateTime date) {
    try {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      // Fallback: Manual Indonesian format
      final day = date.day.toString().padLeft(2, '0');
      final month = getMonthName(date.month);
      final year = date.year.toString();
      return '$day $month $year';
    }
  }

  /// Format date to Indonesian format with day: "Rabu, 19 November 2025"
  static String toIndonesianWithDay(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
  }

  /// Format date to short Indonesian format: "19 Nov 2025"
  static String toIndonesianShort(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  /// Format datetime to Indonesian with time WIB: "19 November 2025, 15:30 WIB"
  static String toIndonesianWithTime(DateTime date) {
    try {
      // Convert to WIB (UTC+7)
      final wibDate = date.toUtc().add(const Duration(hours: 7));
      return '${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(wibDate)} WIB';
    } catch (e) {
      // Fallback: Manual Indonesian format
      final wibDate = date.toUtc().add(const Duration(hours: 7));
      final day = wibDate.day.toString().padLeft(2, '0');
      final month = getMonthName(wibDate.month);
      final year = wibDate.year.toString();
      final hour = wibDate.hour.toString().padLeft(2, '0');
      final minute = wibDate.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute WIB';
    }
  }

  /// Format time only in WIB: "15:30 WIB"
  static String toTimeWIB(DateTime date) {
    // Convert to WIB (UTC+7)
    final wibDate = date.toUtc().add(const Duration(hours: 7));
    return '${DateFormat('HH:mm', 'id_ID').format(wibDate)} WIB';
  }

  /// Parse string date to DateTime (handles null/invalid dates)
  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Format string date to Indonesian format
  static String formatStringToIndonesian(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = parseDate(dateString);
      if (date == null) return dateString; // Return original if can't parse
      return toIndonesian(date);
    } catch (e) {
      print('Error in formatStringToIndonesian: $e');
      return dateString; // Return original on error
    }
  }

  /// Format string datetime to Indonesian with time WIB
  static String formatStringToIndonesianWithTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = parseDate(dateString);
      if (date == null) return dateString; // Return original if can't parse
      return toIndonesianWithTime(date);
    } catch (e) {
      print('Error in formatStringToIndonesianWithTime: $e');
      return dateString; // Return original on error
    }
  }

  /// Get current date/time in WIB
  static DateTime nowWIB() {
    return DateTime.now().toUtc().add(const Duration(hours: 7));
  }

  /// Get month name in Indonesian
  static String getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }
}

