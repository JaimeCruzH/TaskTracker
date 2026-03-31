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

  Future<List<Task>> getTasksByRecurrencePattern(String patternId) async {
    return await _databaseHelper.getTasksByRecurrencePattern(patternId);
  }

  Future<int> countFutureRecurrences(String patternId, String currentId) async {
    final tasks = await getTasksByRecurrencePattern(patternId);
    final today = DateTime.now();
    today.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    return tasks.where((t) {
      return t.id != currentId &&
          t.dueDate != null &&
          !t.dueDate!.isBefore(DateTime(today.year, today.month, today.day));
    }).length;
  }

  Future<void> deleteFutureRecurrences(String patternId, String currentId) async {
    final tasks = await getTasksByRecurrencePattern(patternId);
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    for (final task in tasks) {
      if (task.id != currentId &&
          task.dueDate != null &&
          !task.dueDate!.isBefore(todayStart)) {
        await deleteTask(task.id);
      }
    }
  }

  Future<int> pruneOldCompletedTasks({int daysOld = 30}) async {
    return await _databaseHelper.pruneOldCompletedTasks(daysOld: daysOld);
  }
}