import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../utils/date_utils.dart';
import 'database_helper.dart';

class TaskRepository {
  final DatabaseHelper _databaseHelper;
  final _uuid = const Uuid();
  List<Task> _tasks = [];

  TaskRepository(this._databaseHelper);

  Future<void> loadTasks() async {
    _tasks = await _databaseHelper.getAllTasks();
  }

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

    final idsToDelete = tasks
        .where((t) =>
            t.id != currentId &&
            t.dueDate != null &&
            !t.dueDate!.isBefore(todayStart))
        .map((t) => t.id)
        .toList();

    if (idsToDelete.isEmpty) return;

    final db = await _databaseHelper.database;
    final batch = db.batch();
    for (final id in idsToDelete) {
      batch.delete('tasks', where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  Future<int> pruneOldCompletedTasks({int daysOld = 30}) async {
    return await _databaseHelper.pruneOldCompletedTasks(daysOld: daysOld);
  }

  Map<String, List<Task>> get groupedTasks {
    final allTasks = _tasks.where((t) => t.parentTaskId == null).toList();

    final overdue = <Task>[];
    final today = <Task>[];
    final tomorrow = <Task>[];
    final thisWeek = <Task>[];
    final noDate = <Task>[];
    final completed = <Task>[];

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final weekEnd = todayStart.add(const Duration(days: 7));

    for (final task in allTasks) {
      if (task.isCompleted) {
        completed.add(task);
      } else if (task.dueDate == null) {
        noDate.add(task);
      } else if (task.dueDate!.isBefore(todayStart)) {
        overdue.add(task);
      } else if (DateTimeUtils.isToday(task.dueDate!)) {
        today.add(task);
      } else if (DateTimeUtils.isTomorrow(task.dueDate!)) {
        tomorrow.add(task);
      } else if (task.dueDate!.isBefore(weekEnd)) {
        thisWeek.add(task);
      } else {
        noDate.add(task);
      }
    }

    // Sort completed by completedAt descending, keep only last 20
    completed.sort((a, b) => (b.completedAt ?? DateTime.now()).compareTo(a.completedAt ?? DateTime.now()));
    final limitedCompleted = completed.take(20).toList();

    return {
      'Vencidas': overdue,
      'Hoy': today,
      'Mañana': tomorrow,
      'Esta semana': thisWeek,
      'Sin fecha': noDate,
      'Completadas': limitedCompleted,
    };
  }
}