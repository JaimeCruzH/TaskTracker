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
}