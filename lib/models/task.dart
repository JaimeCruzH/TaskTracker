enum Priority { low, medium, high }

enum RecurrenceType { none, daily, weekly, monthly, yearly }

enum TaskCategory { work, home, health, sport, personal, study, shopping, finance }

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final int? dueTimeHour;
  final int? dueTimeMinute;
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
    this.dueTimeHour,
    this.dueTimeMinute,
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

  bool get hasTime => dueTimeHour != null && dueTimeMinute != null;

  String get formattedDuration {
    if (durationMinutes == null) return 'Sin duración';
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

  String get formattedTime {
    if (!hasTime) return '';
    return '${dueTimeHour.toString().padLeft(2, '0')}:${dueTimeMinute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'dueTimeHour': dueTimeHour,
      'dueTimeMinute': dueTimeMinute,
      'priority': priority.index,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'recurrenceType': recurrenceType.index,
      'recurrencePatternId': recurrencePatternId,
      'parentTaskId': parentTaskId,
      'durationMinutes': durationMinutes,
      'tagIds': tagIds.join(','),
      'dependsOnTaskId': dependsOnTaskId,
      'category': category?.index,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    final timeStr = map['dueTime'] as String?;
    int? hour;
    int? minute;
    if (timeStr != null && timeStr.contains(':')) {
      final parts = timeStr.split(':');
      hour = int.tryParse(parts[0]);
      minute = int.tryParse(parts[1]);
    }

    final tagIdsStr = map['tagIds'] as String?;
    final tagIds = tagIdsStr != null && tagIdsStr.isNotEmpty
        ? tagIdsStr.split(',')
        : <String>[];

    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      dueTimeHour: map['dueTimeHour'] as int? ?? hour,
      dueTimeMinute: map['dueTimeMinute'] as int? ?? minute,
      priority: Priority.values[map['priority'] as int? ?? 1],
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      recurrenceType:
          RecurrenceType.values[map['recurrenceType'] as int? ?? 0],
      recurrencePatternId: map['recurrencePatternId'] as String?,
      parentTaskId: map['parentTaskId'] as String?,
      durationMinutes: map['durationMinutes'] as int?,
      tagIds: tagIds,
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
    int? dueTimeHour,
    int? dueTimeMinute,
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
      dueTimeHour: dueTimeHour ?? this.dueTimeHour,
      dueTimeMinute: dueTimeMinute ?? this.dueTimeMinute,
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
}