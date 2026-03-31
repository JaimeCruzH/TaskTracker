import '../models/task.dart';

class RecurrenceService {
  DateTime calculateNextOccurrence(Task task) {
    if (task.recurrenceType == RecurrenceType.none) {
      throw ArgumentError('Task is not recurring');
    }

    final baseDate = task.dueDate ?? DateTime.now();

    switch (task.recurrenceType) {
      case RecurrenceType.daily:
        return baseDate.add(const Duration(days: 1));
      case RecurrenceType.weekly:
        return baseDate.add(const Duration(days: 7));
      case RecurrenceType.monthly:
        return DateTime(
          baseDate.year,
          baseDate.month + 1,
          baseDate.day,
        );
      case RecurrenceType.yearly:
        return DateTime(
          baseDate.year + 1,
          baseDate.month,
          baseDate.day,
        );
      case RecurrenceType.none:
        return baseDate;
    }
  }

  bool isRecurring(Task task) {
    return task.recurrenceType != RecurrenceType.none;
  }

  String getRecurrenceDescription(Task task) {
    switch (task.recurrenceType) {
      case RecurrenceType.none:
        return 'No se repite';
      case RecurrenceType.daily:
        return 'Diariamente';
      case RecurrenceType.weekly:
        return 'Semanalmente';
      case RecurrenceType.monthly:
        return 'Mensualmente';
      case RecurrenceType.yearly:
        return 'Anualmente';
    }
  }

  List<Task> expandRecurrences(
    Task task, {
    required DateTime startDate,
    required DateTime endDate,
    int maxOccurrences = 100,
  }) {
    if (!isRecurring(task)) {
      return [task];
    }

    final occurrences = <Task>[];
    DateTime currentDate = startDate;
    int count = 0;

    while (currentDate.isBefore(endDate) && count < maxOccurrences) {
      final occurrence = task.copyWith(
        dueDate: currentDate,
        isCompleted: false,
        completedAt: null,
      );
      occurrences.add(occurrence);

      currentDate = calculateNextOccurrence(
        occurrence.copyWith(dueDate: currentDate),
      );
      count++;
    }

    return occurrences;
  }
}