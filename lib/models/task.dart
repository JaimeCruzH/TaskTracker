enum Priority { low, medium, high }

enum RecurrenceType { none, daily, weekly, monthly, yearly }

enum TaskCategory { work, home, health, sport, personal, study, shopping, finance }

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final TimeOfDay? dueTime;
  final Priority priority;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final RecurrenceType recurrenceType;
  final String? recurrencePatternId;
  final String? parentTaskId;
  final int? durationMinutes;
  final List<String> tagIds;
  final int? dependsOnTaskId;
  final TaskCategory? category;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.dueTime,
    this.priority = Priority.medium,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.recurrenceType = RecurrenceType.none,
    this.recurrencePatternId,
    this.parentTaskId,
    this.durationMinutes,
    this.tagIds = const [],
    this.dependsOnTaskId,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'dueTime': dueTime != null
          ? '${dueTime!.hour}:${dueTime!.minute}'
          : null,
      'priority': priority.index,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'recurrenceType': recurrenceType.index,
      'recurrencePatternId': recurrencePatternId,
      'parentTaskId': parentTaskId,
      'durationMinutes': durationMinutes,
      'dependsOnTaskId': dependsOnTaskId,
      'category': category?.index,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null) return null;
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      dueTime: parseTime(map['dueTime'] as String?),
      priority: Priority.values[map['priority'] as int],
      isCompleted: (map['isCompleted'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      recurrenceType:
          RecurrenceType.values[map['recurrenceType'] as int],
      recurrencePatternId: map['recurrencePatternId'] as String?,
      parentTaskId: map['parentTaskId'] as String?,
      durationMinutes: map['durationMinutes'] as int?,
      dependsOnTaskId: map['dependsOnTaskId'] as int?,
      category: map['category'] != null
          ? TaskCategory.values[map['category'] as int]
          : null,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    Priority? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    RecurrenceType? recurrenceType,
    String? recurrencePatternId,
    String? parentTaskId,
    int? durationMinutes,
    List<String>? tagIds,
    int? dependsOnTaskId,
    TaskCategory? category,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrencePatternId:
          recurrencePatternId ?? this.recurrencePatternId,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      tagIds: tagIds ?? this.tagIds,
      dependsOnTaskId: dependsOnTaskId ?? this.dependsOnTaskId,
      category: category ?? this.category,
    );
  }

  String get formattedDuration {
    if (durationMinutes == null) return 'Sin duracion';
    final hours = durationMinutes! ~/ 60;
    final minutes = durationMinutes! % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }
}