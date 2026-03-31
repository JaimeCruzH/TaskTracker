import 'package:intl/intl.dart';

class DateTimeUtils {
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static String formatDateTime(DateTime date, int hour, int minute) {
    return '${formatDate(date)} ${formatTime(hour, minute)}';
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  static bool isOverdue(DateTime? dueDate, TimeOfDay? dueTime) {
    if (dueDate == null) return false;

    final now = DateTime.now();
    final due = dueTime != null
        ? DateTime(dueDate.year, dueDate.month, dueDate.day, dueTime.hour, dueTime.minute)
        : DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59);

    return due.isBefore(now);
  }

  static String getRelativeDate(DateTime date) {
    if (isToday(date)) return 'Hoy';
    if (isTomorrow(date)) return 'Manana';
    return formatDate(date);
  }

  static String getRelativeDateTime(DateTime date, int hour, int minute) {
    final timeStr = formatTime(hour, minute);
    if (isToday(date)) return 'Hoy a las $timeStr';
    if (isTomorrow(date)) return 'Manana a las $timeStr';
    return '${formatDate(date)} a las $timeStr';
  }

  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeOfDay &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}