import 'package:uuid/uuid.dart';
import '../models/task.dart';
import 'database_helper.dart';

class TaskRepository {
  final DatabaseHelper _databaseHelper;
  final _uuid = const Uuid();

  TaskRepository(this._databaseHelper);

  Future<List<Task>> getAllTasks() async {
    return await _databaseHelper.getAllTasks();
  }

  Future<Task?> getTaskById(String id) async {
    return await _databaseHelper.getTaskById(id);
  }

  Future<List<Task>> getSubtasks(String parentId) async {
    return await _databaseHelper.getTasksByParentId(parentId);
  }

  Future<List<Task>> getRootTasks() async {
    return await _databaseHelper.getTasksByParentId(null);
  }

  Future<Task> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    Priority priority = Priority.medium,
    RecurrenceType recurrenceType = RecurrenceType.none,
    String? recurrencePatternId,
    String? parentTaskId,
    int? durationMinutes,
    List<String> tagIds = const [],
  }) async {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      dueTime: dueTime,
      priority: priority,
      isCompleted: false,
      createdAt: DateTime.now(),
      recurrenceType: recurrenceType,
      recurrencePatternId: recurrencePatternId,
      parentTaskId: parentTaskId,
      durationMinutes: durationMinutes,
      tagIds: tagIds,
    );

    await _databaseHelper.insertTask(task);
    return task;
  }

  Future<Task> updateTask(Task task) async {
    await _databaseHelper.updateTask(task);
    return task;
  }

  Future<void> toggleComplete(String id) async {
    final task = await _databaseHelper.getTaskById(id);
    if (task == null) return;

    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    );

    await _databaseHelper.updateTask(updatedTask);
  }

  Future<void> deleteTask(String id) async {
    await _databaseHelper.deleteTask(id);
  }

  Future<int> pruneOldCompletedTasks({int daysOld = 30}) async {
    return await _databaseHelper.pruneOldCompletedTasks(daysOld: daysOld);
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