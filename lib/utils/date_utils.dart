import 'package:intl/intl.dart';
import '../models/task.dart';

class DateTimeUtils {
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static String formatTimeFromTask(Task task) {
    if (!task.hasTime) return '';
    return formatTime(task.dueTimeHour!, task.dueTimeMinute!);
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

  static bool isOverdue(DateTime? dueDate, int? dueTimeHour, int? dueTimeMinute) {
    if (dueDate == null) return false;

    final now = DateTime.now();
    final due = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      dueTimeHour ?? 23,
      dueTimeMinute ?? 59,
    );

    return due.isBefore(now);
  }

  static String getRelativeDate(DateTime date) {
    if (isToday(date)) return 'Hoy';
    if (isTomorrow(date)) return 'Mañana';
    return formatDate(date);
  }

  static String getRelativeDateTime(DateTime date, int hour, int minute) {
    final timeStr = formatTime(hour, minute);
    if (isToday(date)) return 'Hoy a las $timeStr';
    if (isTomorrow(date)) return 'Mañana a las $timeStr';
    return '${formatDate(date)} a las $timeStr';
  }

  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
}