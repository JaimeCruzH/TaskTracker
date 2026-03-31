import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        dueDate TEXT,
        dueTime TEXT,
        priority INTEGER NOT NULL DEFAULT 1,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        recurrenceType INTEGER NOT NULL DEFAULT 0,
        recurrencePatternId TEXT,
        parentTaskId TEXT,
        durationMinutes INTEGER,
        FOREIGN KEY (parentTaskId) REFERENCES tasks(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE recurrence_patterns (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        interval INTEGER NOT NULL DEFAULT 1,
        endDate TEXT,
        count INTEGER,
        daysOfWeek TEXT,
        dayOfMonth INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE task_tags (
        taskId TEXT NOT NULL,
        tagId TEXT NOT NULL,
        PRIMARY KEY (taskId, tagId),
        FOREIGN KEY (taskId) REFERENCES tasks(id) ON DELETE CASCADE,
        FOREIGN KEY (tagId) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final result = await db.query('tasks', orderBy: 'createdAt DESC');
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<Task?> getTaskById(String id) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Task.fromMap(result.first);
  }

  Future<List<Task>> getTasksByParentId(String? parentId) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: parentId == null ? 'parentTaskId IS NULL' : 'parentTaskId = ?',
      whereArgs: parentId == null ? null : [parentId],
    );
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getTasksByRecurrencePattern(String patternId) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'recurrencePatternId = ?',
      whereArgs: [patternId],
    );
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> pruneOldCompletedTasks({int daysOld = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    return await db.delete(
      'tasks',
      where: 'isCompleted = 1 AND completedAt < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  /// Finds tasks that overlap with a proposed time slot.
  /// Takes the proposed date, time, duration in minutes, and optionally a taskId to exclude.
  /// Returns a list of overlapping tasks.
  Future<List<Task>> findOverlappingTasks({
    required DateTime date,
    required TimeOfDay time,
    required int durationMinutes,
    String? currentTaskId,
  }) async {
    final db = await database;
    final overlapping = <Task>{};

    // Convert proposed time to minutes since midnight
    final proposedStartMinutes = time.hour * 60 + time.minute;
    final proposedEndMinutes = proposedStartMinutes + durationMinutes;

    // Helper to check if two ranges overlap [start, end)
    bool rangesOverlap(int start1, int end1, int start2, int end2) {
      return start1 < end2 && start2 < end1;
    }

    // Helper to convert TimeOfDay to minutes since midnight
    int timeToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

    // 1. Query individual (non-recurring) tasks on the same date
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final individualQuery = StringBuffer();
    final individualArgs = <dynamic>[dateStr];

    if (currentTaskId != null) {
      individualQuery.write('recurrenceType = ? AND dueDate = ? AND id != ?');
      individualArgs.insert(0, RecurrenceType.none.index);
      individualArgs.add(currentTaskId);
    } else {
      individualQuery.write('recurrenceType = ? AND dueDate = ?');
      individualArgs.insert(0, RecurrenceType.none.index);
    }

    final individualResults = await db.query(
      'tasks',
      where: individualQuery.toString(),
      whereArgs: individualArgs,
    );

    for (final row in individualResults) {
      final task = Task.fromMap(row);
      if (task.dueTime != null && task.durationMinutes != null) {
        final taskStart = timeToMinutes(task.dueTime!);
        final taskEnd = taskStart + task.durationMinutes!;
        if (rangesOverlap(proposedStartMinutes, proposedEndMinutes, taskStart, taskEnd)) {
          overlapping.add(task);
        }
      }
    }

    // 2. Query recurring tasks and expand occurrences
    final recurringQuery = StringBuffer();
    final recurringArgs = <dynamic>[];

    if (currentTaskId != null) {
      recurringQuery.write('recurrenceType != ? AND dueDate = ? AND id != ?');
      recurringArgs.add(RecurrenceType.none.index);
      recurringArgs.add(dateStr);
      recurringArgs.add(currentTaskId);
    } else {
      recurringQuery.write('recurrenceType != ? AND dueDate = ?');
      recurringArgs.add(RecurrenceType.none.index);
      recurringArgs.add(dateStr);
    }

    final recurringResults = await db.query(
      'tasks',
      where: recurringQuery.toString(),
      whereArgs: recurringArgs,
    );

    for (final row in recurringResults) {
      final task = Task.fromMap(row);
      if (task.dueTime != null && task.durationMinutes != null) {
        // For recurring tasks, check if the given date falls on a valid occurrence
        if (_isValidOccurrence(date, task)) {
          final taskStart = timeToMinutes(task.dueTime!);
          final taskEnd = taskStart + task.durationMinutes!;
          if (rangesOverlap(proposedStartMinutes, proposedEndMinutes, taskStart, taskEnd)) {
            overlapping.add(task);
          }
        }
      }
    }

    return overlapping.toList();
  }

  /// Checks if a given date is a valid occurrence of a recurring task.
  bool _isValidOccurrence(DateTime date, Task task) {
    if (task.dueDate == null) return false;

    final baseDate = task.dueDate!;
    final diff = date.difference(baseDate).inDays;

    if (diff < 0) return false;

    switch (task.recurrenceType) {
      case RecurrenceType.daily:
        return true;
      case RecurrenceType.weekly:
        return diff % 7 == 0;
      case RecurrenceType.monthly:
        return date.day == baseDate.day;
      case RecurrenceType.yearly:
        return date.month == baseDate.month && date.day == baseDate.day;
      case RecurrenceType.none:
        return date.year == baseDate.year &&
               date.month == baseDate.month &&
               date.day == baseDate.day;
    }
  }
}