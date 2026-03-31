# TaskTracker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar TaskTracker Flutter funcional con las 4 modificaciones especificadas: duración en minutos, advertencia de superposición, dialog de eliminación recurrente, y auto-limpieza de 30 días.

**Architecture:** Flutter con MVVM simplificado + Repository pattern. Base de datos SQLite local. Notificaciones locales para recordatorios.

**Tech Stack:** Flutter 3.x, Dart, SQLite (sqflite), flutter_local_notifications, provider (o Riverpod) para estado.

---

## File Structure

```
lib/
├── main.dart                           # Entry point, inicialización DB
├── models/
│   └── task.dart                       # Modelo Task con todas las modificaciones
├── data/
│   ├── database_helper.dart            # SQLite, pruneOldTasks, overlap detection
│   └── task_repository.dart            # Repository CRUD
├── services/
│   ├── notification_service.dart       # Notificaciones locales
│   └── recurrence_service.dart         # Expansión de fechas recurrentes
├── screens/
│   ├── home_screen.dart                # Lista principal con grupos
│   └── task_form_screen.dart           # Create/Edit con duración + overlap warning
├── widgets/
│   ├── task_card.dart                  # Card con duración y candado
│   ├── priority_chip.dart              # Chip de prioridad
│   ├── recurrence_selector.dart         # Selector de recurrencia
│   ├── dependency_picker.dart          # Selector de dependencia
│   ├── overdue_dialog.dart             # Dialog de tarea vencida
│   ├── overlap_warning.dart            # Widget inline de superposición
│   └── duration_selector.dart          # Stepper de duración
└── utils/
    └── date_utils.dart                 # Helpers de fecha
```

---

## Task 1: Crear proyecto Flutter base

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/main.dart`
- Create: `lib/models/task.dart`
- Create: `lib/data/database_helper.dart`
- Create: `lib/data/task_repository.dart`
- Create: `lib/services/notification_service.dart`
- Create: `lib/services/recurrence_service.dart`
- Create: `lib/screens/home_screen.dart`
- Create: `lib/screens/task_form_screen.dart`
- Create: `lib/widgets/task_card.dart`
- Create: `lib/widgets/priority_chip.dart`
- Create: `lib/widgets/recurrence_selector.dart`
- Create: `lib/widgets/dependency_picker.dart`
- Create: `lib/widgets/overdue_dialog.dart`
- Create: `lib/utils/date_utils.dart`

- [ ] **Step 1: Crear pubspec.yaml**

```yaml
name: task_tracker
description: Aplicación de gestión de tareas para Android
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path: ^1.8.3
  flutter_local_notifications: ^17.0.0
  intl: ^0.18.1
  provider: ^6.1.1
  uuid: ^4.2.1
  timezone: ^0.9.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
```

- [ ] **Step 2: Crear lib/main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/database_helper.dart';
import 'data/task_repository.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = DatabaseHelper.instance;
  await db.database; // ensure initialized
  await db.pruneOldCompletedTasks(); // Auto-limpieza al iniciar

  runApp(
    ChangeNotifierProvider(
      create: (_) => TaskRepository(db),
      child: const TaskTrackerApp(),
    ),
  );
}

class TaskTrackerApp extends StatelessWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskTracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
```

- [ ] **Step 3: Crear lib/models/task.dart**

```dart
enum Priority { high, medium, low }

enum RecurrenceType { none, daily, weekly, monthly, everyXDays }

enum TaskCategory { work, home, health, sport, personal, study, shopping, finance }

class Task {
  int? id;
  String title;
  String description;
  Priority priority;
  TaskCategory? category;
  DateTime? dueDate;
  TimeOfDay? dueTime;
  bool isCompleted;
  DateTime createdAt;

  // Recurrencia
  RecurrenceType recurrence;
  int? recurrenceInterval;
  List<int>? weeklyDays;
  String? recurrencePatternId; // UUID - identifica grupo de recurrencia

  // Duración (Modificación 1)
  int? durationMinutes; // 1-1440, nullable

  // Dependencias
  int? dependsOnTaskId;

  // Notificaciones
  bool notificationEnabled;
  int? notificationId;

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.priority = Priority.medium,
    this.category,
    this.dueDate,
    this.dueTime,
    this.isCompleted = false,
    DateTime? createdAt,
    this.recurrence = RecurrenceType.none,
    this.recurrenceInterval,
    this.weeklyDays,
    this.recurrencePatternId,
    this.durationMinutes,
    this.dependsOnTaskId,
    this.notificationEnabled = true,
    this.notificationId,
  }) : createdAt = createdAt ?? DateTime.now();

  // Constructor desde mapa (SQLite)
  Task.fromMap(Map<String, dynamic> map) {
    id = map['id'] as int?;
    title = map['title'] as String;
    description = map['description'] as String? ?? '';
    priority = Priority.values[map['priority'] as int];
    category = map['category'] != null
        ? TaskCategory.values[map['category'] as int]
        : null;
    dueDate = map['dueDate'] != null
        ? DateTime.parse(map['dueDate'] as String)
        : null;
    dueTime = map['dueTime'] != null
        ? TimeOfDay(
            hour: int.parse((map['dueTime'] as String).split(':')[0]),
            minute: int.parse((map['dueTime'] as String).split(':')[1]),
          )
        : null;
    isCompleted = (map['isCompleted'] as int) == 1;
    createdAt = DateTime.parse(map['createdAt'] as String);
    recurrence = RecurrenceType.values[map['recurrence'] as int? ?? 0];
    recurrenceInterval = map['recurrenceInterval'] as int?;
    weeklyDays = map['weeklyDays'] != null
        ? (map['weeklyDays'] as String).split(',').map(int.parse).toList()
        : null;
    recurrencePatternId = map['recurrencePatternId'] as String?;
    durationMinutes = map['durationMinutes'] as int?;
    dependsOnTaskId = map['dependsOnTaskId'] as int?;
    notificationEnabled = (map['notificationEnabled'] as int? ?? 1) == 1;
    notificationId = map['notificationId'] as int?;
  }

  // Convertir a mapa para SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'category': category?.index,
      'dueDate': dueDate?.toIso8601String().split('T')[0],
      'dueTime': dueTime != null
          ? '${dueTime!.hour.toString().padLeft(2, '0')}:${dueTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'recurrence': recurrence.index,
      'recurrenceInterval': recurrenceInterval,
      'weeklyDays': weeklyDays?.join(','),
      'recurrencePatternId': recurrencePatternId,
      'durationMinutes': durationMinutes,
      'dependsOnTaskId': dependsOnTaskId,
      'notificationEnabled': notificationEnabled ? 1 : 0,
      'notificationId': notificationId,
    };
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    Priority? priority,
    TaskCategory? category,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    bool? isCompleted,
    DateTime? createdAt,
    RecurrenceType? recurrence,
    int? recurrenceInterval,
    List<int>? weeklyDays,
    String? recurrencePatternId,
    int? durationMinutes,
    int? dependsOnTaskId,
    bool? notificationEnabled,
    int? notificationId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      recurrence: recurrence ?? this.recurrence,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      recurrencePatternId: recurrencePatternId ?? this.recurrencePatternId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      dependsOnTaskId: dependsOnTaskId ?? this.dependsOnTaskId,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  String get formattedDuration {
    if (durationMinutes == null) return '';
    if (durationMinutes! >= 60) {
      final h = durationMinutes! ~/ 60;
      final m = durationMinutes! % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '${durationMinutes}m';
  }

  DateTime? get dueDateTime {
    if (dueDate == null) return null;
    return DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      dueTime?.hour ?? 0,
      dueTime?.minute ?? 0,
    );
  }
}
```

- [ ] **Step 4: Crear lib/data/database_helper.dart**

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _db;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('task_tracker.db');
    return _db!;
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
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        priority INTEGER NOT NULL DEFAULT 1,
        category INTEGER,
        dueDate TEXT,
        dueTime TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        recurrence INTEGER NOT NULL DEFAULT 0,
        recurrenceInterval INTEGER,
        weeklyDays TEXT,
        recurrencePatternId TEXT,
        durationMinutes INTEGER,
        dependsOnTaskId INTEGER,
        notificationEnabled INTEGER NOT NULL DEFAULT 1,
        notificationId INTEGER,
        FOREIGN KEY (dependsOnTaskId) REFERENCES tasks(id)
      )
    ''');
  }

  // Modificación 4: Auto-limpieza de tareas completadas > 30 días
  Future<void> pruneOldCompletedTasks({int daysToKeep = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    await db.delete(
      'tasks',
      where: 'isCompleted = 1 AND createdAt < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  // Modificación 2: Detectar superposición de tareas
  Future<List<Map<String, dynamic>>> findOverlappingTasks({
    required DateTime date,
    required TimeOfDay time,
    int? durationMinutes,
    int? currentTaskId,
  }) async {
    final db = await database;

    // Buscar tareas individuales con fecha/hora
    final dateStr = date.toIso8601String().split('T')[0];
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    final individualOverlap = await db.rawQuery('''
      SELECT * FROM tasks
      WHERE dueDate = ?
        AND dueTime IS NOT NULL
        AND id != ?
        AND isCompleted = 0
    ''', [dateStr, currentTaskId ?? -1]);

    return individualOverlap;
  }

  // Query básica de tareas
  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final db = await database;
    return await db.query('tasks', orderBy: 'dueDate ASC, priority DESC');
  }

  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.insert('tasks', task);
  }

  Future<int> updateTask(int id, Map<String, dynamic> task) async {
    final db = await database;
    return await db.update('tasks', task, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Contar futuras recurrencias para dialog de eliminación
  Future<int> countFutureRecurrences(String patternId, int currentId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM tasks
      WHERE recurrencePatternId = ?
        AND id != ?
        AND dueDate >= ?
    ''', [patternId, currentId, today]);
    return result.first['count'] as int;
  }

  // Eliminar futuras recurrencias
  Future<void> deleteFutureRecurrences(String patternId, int currentId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    await db.delete(
      'tasks',
      where: 'recurrencePatternId = ? AND id != ? AND dueDate >= ?',
      whereArgs: [patternId, currentId, today],
    );
  }
}

class TimeOfDay {
  final int hour;
  final int minute;
  const TimeOfDay({required this.hour, required this.minute});
}
```

- [ ] **Step 5: Crear lib/data/task_repository.dart**

```dart
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import 'database_helper.dart';

class TaskRepository extends ChangeNotifier {
  final DatabaseHelper _db;
  List<Task> _tasks = [];

  TaskRepository(this._db);

  List<Task> get tasks => _tasks;

  Future<void> loadTasks() async {
    final maps = await _db.getAllTasks();
    _tasks = maps.map((m) => Task.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    await _db.insertTask(task.toMap());
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    if (task.id == null) return;
    await _db.updateTask(task.id!, task.toMap());
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await _db.deleteTask(id);
    await loadTasks();
  }

  Future<int> countFutureRecurrences(String patternId, int currentId) {
    return _db.countFutureRecurrences(patternId, currentId);
  }

  Future<void> deleteFutureRecurrences(String patternId, int currentId) {
    return _db.deleteFutureRecurrences(patternId, currentId);
  }

  List<Task> get pendingTasks =>
      _tasks.where((t) => !t.isCompleted).toList()
        ..sort((a, b) {
          final dateCmp = (a.dueDate ?? DateTime(2099)).compareTo(b.dueDate ?? DateTime(2099));
          if (dateCmp != 0) return dateCmp;
          return b.priority.index.compareTo(a.priority.index);
        });

  List<Task> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // Agrupación por fecha
  Map<String, List<Task>> get groupedTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    final Map<String, List<Task>> groups = {
      'Vencidas': [],
      'Hoy': [],
      'Mañana': [],
      'Esta semana': [],
      'Sin fecha': [],
      'Completadas': [],
    };

    for (final task in pendingTasks) {
      if (task.dueDate == null) {
        groups['Sin fecha']!.add(task);
      } else if (task.dueDate!.isBefore(today)) {
        groups['Vencidas']!.add(task);
      } else if (task.dueDate!.isAtSameMomentAs(today)) {
        groups['Hoy']!.add(task);
      } else if (task.dueDate!.isAtSameMomentAs(tomorrow)) {
        groups['Mañana']!.add(task);
      } else if (task.dueDate!.isBefore(weekEnd)) {
        groups['Esta semana']!.add(task);
      } else {
        groups['Esta semana']!.add(task);
      }
    }

    groups['Completadas'] = completedTasks.take(20).toList();
    return groups;
  }
}
```

- [ ] **Step 6: Crear lib/services/recurrence_service.dart**

```dart
import '../models/task.dart';

class RecurrenceService {
  DateTime calculateNextOccurrence(Task task) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (task.recurrence) {
      case RecurrenceType.none:
        return task.dueDate ?? today;

      case RecurrenceType.daily:
        return (task.dueDate ?? today).add(const Duration(days: 1));

      case RecurrenceType.weekly:
        return _nextWeeklyDate(task, today);

      case RecurrenceType.monthly:
        return _nextMonthlyDate(task, today);

      case RecurrenceType.everyXDays:
        final interval = task.recurrenceInterval ?? 1;
        return (task.dueDate ?? today).add(Duration(days: interval));
    }
  }

  DateTime _nextWeeklyDate(Task task, DateTime today) {
    final days = task.weeklyDays ?? [];
    if (days.isEmpty) return today.add(const Duration(days: 7));

    final currentWeekday = today.weekday; // 1=Lunes, 7=Domingo
    final sortedDays = List<int>.from(days)..sort();

    for (final day in sortedDays) {
      if (day > currentWeekday) {
        return today.add(Duration(days: day - currentWeekday));
      }
    }
    // Volver al primer día de la próxima semana
    return today.add(Duration(days: 7 - currentWeekday + sortedDays.first));
  }

  DateTime _nextMonthlyDate(Task task, DateTime today) {
    final originalDay = task.dueDate?.day ?? today.day;
    var nextMonth = DateTime(today.year, today.month + 1, originalDay);
    if (nextMonth.isBefore(today)) {
      nextMonth = DateTime(today.year, today.month + 2, originalDay);
    }
    return nextMonth;
  }

  // Expandir recurrencias para detección de superposición
  List<DateTime> expandRecurrences(Task task, {int count = 15}) {
    final dates = <DateTime>[];
    var currentDate = task.dueDate ?? DateTime.now();
    final endDate = currentDate.add(const Duration(days: 90)); // max 90 días

    while (dates.length < count && currentDate.isBefore(endDate)) {
      dates.add(currentDate);
      currentDate = calculateNextOccurrence(
        task.copyWith(dueDate: currentDate),
      );
    }

    return dates;
  }
}
```

- [ ] **Step 7: Crear lib/widgets/priority_chip.dart**

```dart
import 'package:flutter/material.dart';
import '../models/task.dart';

class PriorityChip extends StatelessWidget {
  final Priority priority;

  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Color get _color {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.amber;
      case Priority.low:
        return Colors.green;
    }
  }

  String get _label {
    switch (priority) {
      case Priority.high:
        return 'ALTA';
      case Priority.medium:
        return 'MEDIA';
      case Priority.low:
        return 'BAJA';
    }
  }
}
```

- [ ] **Step 8: Crear lib/utils/date_utils.dart**

```dart
import 'package:intl/intl.dart';

class DateUtils {
  static String formatDate(DateTime date) {
    return DateFormat('d MMM').format(date);
  }

  static String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  static String formatDateTime(DateTime date, TimeOfDay? time) {
    final dateStr = formatDate(date);
    if (time == null) return dateStr;
    return '$dateStr ${formatTime(time)}';
  }

  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff < 0) return 'Venció';
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff < 7) return 'Esta semana';
    return formatDate(date);
  }
}

class TimeOfDay {
  final int hour;
  final int minute;
  const TimeOfDay({required this.hour, required this.minute});
}
```

- [ ] **Step 9: Commit**

```bash
git add -A && git commit -m "$(cat <<'EOF'
feat: scaffold proyecto Flutter base TaskTracker

Estructura inicial con:
- Modelo Task con campos completos
- DatabaseHelper con SQLite
- TaskRepository con ChangeNotifier
- RecurrenceService para expansión de fechas
- Widgets base (PriorityChip, DateUtils)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)" && git push
```

---

## Task 2: Modificación 1 - Duración en minutos

**Files:**
- Modify: `lib/screens/task_form_screen.dart` — agregar campo duration
- Modify: `lib/widgets/task_card.dart` — mostrar duración
- Modify: `lib/data/database_helper.dart` — agregar columna durationMinutes
- Modify: `lib/data/task_repository.dart` — pasar durationMinutes en queries

- [ ] **Step 1: Modificar database_helper.dart - actualizar _createDB**

```dart
await db.execute('''
  CREATE TABLE tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    priority INTEGER NOT NULL DEFAULT 1,
    category INTEGER,
    dueDate TEXT,
    dueTime TEXT,
    isCompleted INTEGER NOT NULL DEFAULT 0,
    createdAt TEXT NOT NULL,
    recurrence INTEGER NOT NULL DEFAULT 0,
    recurrenceInterval INTEGER,
    weeklyDays TEXT,
    recurrencePatternId TEXT,
    durationMinutes INTEGER,  // NUEVO
    dependsOnTaskId INTEGER,
    notificationEnabled INTEGER NOT NULL DEFAULT 1,
    notificationId INTEGER,
    FOREIGN KEY (dependsOnTaskId) REFERENCES tasks(id)
  )
''');
```

- [ ] **Step 2: Crear lib/widgets/duration_selector.dart**

```dart
import 'package:flutter/material.dart';

class DurationSelector extends StatefulWidget {
  final int? initialMinutes;
  final ValueChanged<int?> onChanged;

  const DurationSelector({
    super.key,
    this.initialMinutes,
    required this.onChanged,
  });

  @override
  State<DurationSelector> createState() => _DurationSelectorState();
}

class _DurationSelectorState extends State<DurationSelector> {
  late int? _minutes;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialMinutes;
  }

  void _increment() {
    if (_minutes == null) {
      setState(() => _minutes = 15);
    } else if (_minutes! < 1440) {
      setState(() => _minutes = _minutes! + 15);
    }
    widget.onChanged(_minutes);
  }

  void _decrement() {
    if (_minutes != null && _minutes! > 15) {
      setState(() => _minutes = _minutes! - 15);
    } else {
      setState(() => _minutes = null);
    }
    widget.onChanged(_minutes);
  }

  String _formatDuration(int? mins) {
    if (mins == null) return 'Sin duración';
    if (mins >= 60) {
      final h = mins ~/ 60;
      final m = mins % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: _decrement,
          iconSize: 20,
        ),
        GestureDetector(
          onTap: () => _showPicker(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 18),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(_minutes),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _increment,
          iconSize: 20,
        ),
      ],
    );
  }

  void _showPicker() {
    showTimePicker(
      context: context,
      initialTime: _minutes != null
          ? TimeOfDay(hour: _minutes! ~/ 60, minute: _minutes! % 60)
          : const TimeOfDay(hour: 0, minute: 30),
      helpText: 'Seleccionar duración',
    ).then((time) {
      if (time != null) {
        final totalMins = time.hour * 60 + time.minute;
        if (totalMins > 0 && totalMins <= 1440) {
          setState(() => _minutes = totalMins);
          widget.onChanged(_minutes);
        }
      }
    });
  }
}
```

- [ ] **Step 3: Modificar task_form_screen.dart - agregar campo duración**

Ubicar en TaskFormScreen, después del campo de hora, el DurationSelector:

```dart
// En el formulario, después del row de fecha/hora:
Row(
  children: [
    Expanded(
      child: _buildDateField(),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: _buildTimeField(),
    ),
  ],
),
const SizedBox(height: 16),
// NUEVO: DurationSelector
Row(
  children: [
    const Text('Duración:', style: TextStyle(fontSize: 16)),
    const SizedBox(width: 16),
    DurationSelector(
      initialMinutes: _task.durationMinutes,
      onChanged: (mins) {
        setState(() {
          _task = _task.copyWith(durationMinutes: mins);
        });
      },
    ),
  ],
),
```

- [ ] **Step 4: Modificar task_card.dart - mostrar duración**

```dart
// En TaskCard, después de mostrar la hora, agregar:
if (task.durationMinutes != null) ...[
  const SizedBox(width: 4),
  const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
  const SizedBox(width: 2),
  Text(
    task.formattedDuration,
    style: const TextStyle(fontSize: 12, color: Colors.grey),
  ),
],
```

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "$(cat <<'EOF'
feat: agregar duración en minutos a tareas

- Campo durationMinutes (1-1440) en Task
- DurationSelector widget con stepper +15m y TimePicker
- Mostrar duración en TaskCard con icono de reloj
- ALTER TABLE para agregar columna

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)" && git push
```

---

## Task 3: Modificación 4 - Auto-limpieza de 30 días

**Files:**
- Modify: `lib/data/database_helper.dart` — método pruneOldCompletedTasks ya existe
- Modify: `lib/main.dart` — llamado a pruneOldCompletedTasks

- [ ] **Step 1: Verificar que pruneOldCompletedTasks esté en database_helper.dart**

El método ya fue creado en Task 1, Step 4. Verificar que usa `createdAt` correctamente.

- [ ] **Step 2: En main.dart, ya se llama pruneOldCompletedTasks al inicio**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseHelper.instance;
  await db.database;
  await db.pruneOldCompletedTasks(); // Ya está aquí
  // ... resto
}
```

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "$(cat <<'EOF'
feat: auto-limpieza de tareas completadas > 30 días

- pruneOldCompletedTasks() elimina tareas completadas antiguas
- Se ejecuta en main() antes de runApp()
- Solo elimina completadas, preserva vencidas pendientes

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)" && git push
```

---

## Task 4: Modificación 3 - Dialog eliminar tarea recurrente

**Files:**
- Modify: `lib/models/task.dart` — recurrencePatternId (ya existe)
- Modify: `lib/widgets/overdue_dialog.dart` — dialog de confirmación con dos opciones
- Modify: `lib/screens/home_screen.dart` — usar dialog al eliminar
- Modify: `lib/services/recurrence_service.dart` — calculateNextOccurrence para "solo esta"
- Modify: `lib/data/task_repository.dart` — deleteFutureRecurrences

- [ ] **Step 1: Crear lib/widgets/delete_recurring_dialog.dart**

```dart
import 'package:flutter/material.dart';

class DeleteRecurringDialog extends StatefulWidget {
  final String taskTitle;
  final String recurrenceDescription;
  final Future<int> Function() countFutureRecurrences;

  const DeleteRecurringDialog({
    super.key,
    required this.taskTitle,
    required this.recurrenceDescription,
    required this.countFutureRecurrences,
  });

  @override
  State<DeleteRecurringDialog> createState() => _DeleteRecurringDialogState();
}

class _DeleteRecurringDialogState extends State<DeleteRecurringDialog> {
  int _futureCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final count = await widget.countFutureRecurrences();
    if (mounted) {
      setState(() {
        _futureCount = count;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.delete_outline, color: Colors.red),
          const SizedBox(width: 8),
          const Text('Eliminar tarea recurrente'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${widget.taskTitle}"',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(widget.recurrenceDescription),
          const SizedBox(height: 16),
          const Text('¿Qué querés eliminar?'),
          const SizedBox(height: 8),
          RadioListTile<String>(
            title: const Text('Solo esta repetición'),
            subtitle: Text(_getThisOccurrenceTitle()),
            value: 'this',
            groupValue: null,
            onChanged: (v) => Navigator.pop(context, 'this'),
          ),
          RadioListTile<String>(
            title: Text('Todas las futuras (${_futureCount}tareas)'),
            subtitle: const Text('Desde hoy en adelante'),
            value: 'all',
            groupValue: null,
            onChanged: _loading ? null : (v) => Navigator.pop(context, 'all'),
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  String _getThisOccurrenceTitle() {
    final now = DateTime.now();
    return 'Hoy ${now.day}/${now.month}';
  }
}
```

- [ ] **Step 2: Modificar home_screen.dart - usar dialog al eliminar**

En HomeScreen, modificar el onDismissed del Dismissible de tarea:

```dart
Dismissible(
  key: Key(task.id.toString()),
  direction: DismissDirection.horizontal,
  confirmDismiss: (direction) async {
    if (direction == DismissDirection.endToStart) {
      // Eliminar
      if (task.recurrence != RecurrenceType.none && task.recurrencePatternId != null) {
        final result = await showDialog<String>(
          context: context,
          builder: (_) => DeleteRecurringDialog(
            taskTitle: task.title,
            recurrenceDescription: _getRecurrenceDescription(task),
            countFutureRecurrences: () => repo.countFutureRecurrences(
              task.recurrencePatternId!,
              task.id!,
            ),
          ),
        );
        if (result == null) return false;
        if (result == 'this') {
          // Eliminar esta y crear próxima
          await _deleteAndReschedule(task);
          return false; // Ya se manejó
        } else {
          // Eliminar todas las futuras
          await repo.deleteFutureRecurrences(task.recurrencePatternId!, task.id!);
        }
      }
      await repo.deleteTask(task.id!);
      return true;
    } else {
      // Completar
      await repo.updateTask(task.copyWith(isCompleted: true));
      return false;
    }
  },
  background: _buildSwipeBackground(Colors.green, Icons.check),
  secondaryBackground: _buildSwipeBackground(Colors.red, Icons.delete),
  child: TaskCard(task: task),
);
```

- [ ] **Step 3: Agregar método _deleteAndReschedule en home_screen.dart**

```dart
Future<void> _deleteAndReschedule(Task task) async {
  final repo = context.read<TaskRepository>();
  final recurrenceService = RecurrenceService();

  // 1. Calcular próxima ocurrencia
  final nextDate = recurrenceService.calculateNextOccurrence(task);

  // 2. Eliminar tarea actual
  await repo.deleteTask(task.id!);

  // 3. Crear nueva tarea con próxima fecha
  final newTask = task.copyWith(
    id: null,
    dueDate: nextDate,
    createdAt: DateTime.now(),
    isCompleted: false,
    notificationId: null,
  );
  await repo.addTask(newTask);
}

String _getRecurrenceDescription(Task task) {
  switch (task.recurrence) {
    case RecurrenceType.daily:
      return 'Diariamente';
    case RecurrenceType.weekly:
      final days = task.weeklyDays ?? [];
      return 'Semanal (${days.join(", ")})';
    case RecurrenceType.monthly:
      return 'Mensualmente';
    case RecurrenceType.everyXDays:
      return 'Cada ${task.recurrenceInterval} días';
    default:
      return '';
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "$(cat <<'EOF'
feat: dialog de confirmación al eliminar tarea recurrente

- DeleteRecurringDialog con opciones: solo esta vs todas futuras
- countFutureRecurrences() muestra cuántas se eliminarán
- _deleteAndReschedule() elimina actual y programa próxima ocurrencia
- deleteFutureRecurrences() elimina grupo completo desde hoy

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)" && git push
```

---

## Task 5: Modificación 2 - Advertencia de superposición

**Files:**
- Modify: `lib/widgets/overlap_warning.dart` — widget inline de warning
- Modify: `lib/screens/task_form_screen.dart` — integrar overlap detection
- Modify: `lib/data/database_helper.dart` — query de superposición completa
- Modify: `lib/services/recurrence_service.dart` — expandRecurrences para detectar conflictos

- [ ] **Step 1: Crear lib/widgets/overlap_warning.dart**

```dart
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/date_utils.dart' as utils;

class OverlapWarning extends StatelessWidget {
  final List<Task> overlappingTasks;
  final VoidCallback onCreateAnyway;
  final VoidCallback onChangeSchedule;

  const OverlapWarning({
    super.key,
    required this.overlappingTasks,
    required this.onCreateAnyway,
    required this.onChangeSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Esta tarea se superpone con:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...overlappingTasks.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(
                      '"${task.title}" — ${task.dueDateTime != null ? utils.DateUtils.formatDateTime(task.dueDate!, task.dueTime) : "Sin hora"}',
                    ),
                  ),
                  if (task.durationMinutes != null)
                    Text(
                      task.formattedDuration,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            )),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCreateAnyway,
                  child: const Text('Crear igual'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onChangeSchedule,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Cambiar horario'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Modificar database_helper.dart - query de superposición completa**

Reemplazar findOverlappingTasks para incluir recurrencias expandidas:

```dart
// Modificación 2: Detectar superposición de tareas (individuales + recurrentes)
Future<List<Task>> findOverlappingTasks({
  required DateTime date,
  required TimeOfDay time,
  int? durationMinutes,
  int? currentTaskId,
}) async {
  final db = await database;
  final dateStr = date.toIso8601String().split('T')[0];

  // 1. Tareas individuales con fecha/hora
  final individualResults = await db.query(
    'tasks',
    where: 'dueDate = ? AND dueTime IS NOT NULL AND id != ? AND isCompleted = 0',
    whereArgs: [dateStr, currentTaskId ?? -1],
  );

  final overlapping = individualResults.map((m) => Task.fromMap(m)).toList();

  // 2. Tareas recurrentes - expandir próximas ocurrencias
  final recurringResults = await db.query(
    'tasks',
    where: 'recurrence != 0 AND isCompleted = 0 AND id != ?',
    whereArgs: [currentTaskId ?? -1],
  );

  final recurrenceService = RecurrenceService();
  final targetMinutes = time.hour * 60 + time.minute;
  final taskDuration = durationMinutes ?? 30;

  for (final map in recurringResults) {
    final task = Task.fromMap(map);
    final occurrences = recurrenceService.expandRecurrences(task, count: 15);

    for (final occDate in occurrences) {
      if (occDate.year == date.year &&
          occDate.month == date.month &&
          occDate.day == date.day) {
        final occMinutes = occDate.hour * 60 + occDate.minute;
        // Check overlap: [occStart, occStart+duration] overlaps [target, target+taskDuration]
        if (_rangesOverlap(
          targetMinutes,
          targetMinutes + taskDuration,
          occMinutes,
          occMinutes + (task.durationMinutes ?? 30),
        )) {
          overlapping.add(task.copyWith(dueDate: occDate));
          break;
        }
      }
    }
  }

  return overlapping;
}

bool _rangesOverlap(int aStart, int aEnd, int bStart, int bEnd) {
  return aStart < bEnd && bStart < aEnd;
}
```

- [ ] **Step 3: Modificar task_form_screen.dart - integrar overlap detection**

Agregar state variable y lógica de detección:

```dart
class _TaskFormScreenState extends State<TaskFormScreen> {
  Task _task = Task(title: '');
  List<Task> _overlappingTasks = [];
  bool _checkingOverlap = false;
  final _debouncer = Debouncer(milliseconds: 300);

  void _checkOverlap() {
    if (_task.dueDate == null || _task.dueTime == null) {
      setState(() => _overlappingTasks = []);
      return;
    }

    _debouncer.run(() async {
      setState(() => _checkingOverlap = true);

      final overlapping = await DatabaseHelper.instance.findOverlappingTasks(
        date: _task.dueDate!,
        time: _task.dueTime!,
        durationMinutes: _task.durationMinutes,
        currentTaskId: widget.task?.id,
      );

      if (mounted) {
        setState(() {
          _overlappingTasks = overlapping;
          _checkingOverlap = false;
        });
      }
    });
  }
}
```

Agregar en el widget build, después del DurationSelector:

```dart
// Después de DurationSelector, en el formulario:
const SizedBox(height: 16),
if (_checkingOverlap)
  const Center(child: CircularProgressIndicator())
else if (_overlappingTasks.isNotEmpty)
  OverlapWarning(
    overlappingTasks: _overlappingTasks,
    onCreateAnyway: () => _saveTask(),
    onChangeSchedule: () {
      // Focus en el campo de fecha
    },
  ),
```

Y en los callbacks de fecha/hora/duración, llamar `_checkOverlap()`.

- [ ] **Step 4: Crear Debouncer helper**

```dart
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "$(cat <<'EOF'
feat: advertencia de superposición de tareas

- OverlapWarning widget inline con opciones Crear igual / Cambiar horario
- findOverlappingTasks() detecta conflictos con individuales y recurrentes
- expandRecurrences() del RecurrenceService para proyectar 15 ocurrencias
- Debouncer de 300ms para evitar queries excesivos
- Validación de rango: [start, end) overlap check

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)" && git push
```

---

## Task 6: Implementar HomeScreen completo con grupos

**Files:**
- Modify: `lib/screens/home_screen.dart` — pantalla principal con TaskCards

- [ ] **Step 1: Crear lib/screens/home_screen.dart completo**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/task_repository.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import '../widgets/overdue_dialog.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskRepository>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskTracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<TaskRepository>(
        builder: (context, repo, child) {
          if (repo.tasks.isEmpty) {
            return const Center(
              child: Text('No hay tareas.\n¡Toca + para crear una!'),
            );
          }

          final groups = repo.groupedTasks;

          return ListView.builder(
            itemCount: groups.keys.length,
            itemBuilder: (context, index) {
              final groupName = groups.keys.elementAt(index);
              final tasks = groups[groupName]!;

              if (tasks.isEmpty && groupName != 'Completadas') {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      groupName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...tasks.map((task) => _buildTaskItem(task, repo)),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskForm(context),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTaskItem(Task task, TaskRepository repo) {
    return Dismissible(
      key: Key(task.id.toString()),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete
          if (task.recurrence != RecurrenceType.none && task.recurrencePatternId != null) {
            final result = await _showDeleteDialog(task, repo);
            if (result == null) return false;
          }
          await repo.deleteTask(task.id!);
          return true;
        } else {
          // Complete
          if (task.dependsOnTaskId != null) {
            final parent = repo.tasks.firstWhere(
              (t) => t.id == task.dependsOnTaskId,
              orElse: () => task,
            );
            if (!parent.isCompleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Bloqueada por: ${parent.title}')),
              );
              return false;
            }
          }
          await repo.updateTask(task.copyWith(isCompleted: true));
          return false;
        }
      },
      background: _buildSwipeBackground(Colors.green, Icons.check),
      secondaryBackground: _buildSwipeBackground(Colors.red, Icons.delete),
      child: TaskCard(task: task),
    );
  }

  Widget _buildSwipeBackground(Color color, IconData icon) {
    return Container(
      color: color,
      alignment: color == Colors.green
          ? Alignment.centerLeft
          : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: Colors.white),
    );
  }

  Future<String?> _showDeleteDialog(Task task, TaskRepository repo) async {
    return showDialog<String>(
      context: context,
      builder: (_) => _DeleteRecurringDialog(
        taskTitle: task.title,
        recurrenceDescription: _getRecurrenceDescription(task),
        countFutureRecurrences: () =>
            repo.countFutureRecurrences(task.recurrencePatternId!, task.id!),
      ),
    );
  }

  Future<void> _openTaskForm(BuildContext context, [Task? task]) async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(task: task),
      ),
    );
    if (result != null && mounted) {
      final repo = context.read<TaskRepository>();
      if (task == null) {
        await repo.addTask(result);
      } else {
        await repo.updateTask(result);
      }
    }
  }

  String _getRecurrenceDescription(Task task) {
    switch (task.recurrence) {
      case RecurrenceType.daily:
        return 'Diariamente';
      case RecurrenceType.weekly:
        return 'Semanal (${task.weeklyDays?.join(", ")})';
      case RecurrenceType.monthly:
        return 'Mensualmente';
      case RecurrenceType.everyXDays:
        return 'Cada ${task.recurrenceInterval} días';
      default:
        return '';
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "$(cat <<'EOF'
feat: home screen completo con grupos y swipe actions

- Lista agrupada: Vencidas, Hoy, Mañana, Esta semana, Sin fecha, Completadas
- Swipe izquierda = completar, swipe derecha = eliminar
- Dialog de confirmación para tareas recurrentes
- FAB para crear nueva tarea
- Navegación a TaskFormScreen

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)" && git push
```

---

## Task 7: Implementar TaskFormScreen completo

**Files:**
- Modify: `lib/screens/task_form_screen.dart` — formulario completo create/edit

- [ ] **Step 1: Crear lib/screens/task_form_screen.dart completo**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../data/database_helper.dart';
import '../data/task_repository.dart';
import '../models/task.dart';
import '../widgets/duration_selector.dart';
import '../widgets/overlap_warning.dart';
import '../utils/date_utils.dart' as utils;

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  late Task _task;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  List<Task> _overlappingTasks = [];
  bool _checkingOverlap = false;
  bool _saving = false;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _task = widget.task?.copyWith() ?? Task(title: '');
    _titleController.text = _task.title;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _checkOverlap() async {
    if (_task.dueDate == null || _task.dueTime == null) {
      setState(() => _overlappingTasks = []);
      return;
    }

    setState(() => _checkingOverlap = true);

    final overlapping = await DatabaseHelper.instance.findOverlappingTasks(
      date: _task.dueDate!,
      time: _task.dueTime!,
      durationMinutes: _task.durationMinutes,
      currentTaskId: widget.task?.id,
    );

    if (mounted) {
      setState(() {
        _overlappingTasks = overlapping;
        _checkingOverlap = false;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final taskToSave = _task.copyWith(
      title: _titleController.text.trim(),
      recurrencePatternId: _task.recurrencePatternId ??
          (isEditing ? _task.recurrencePatternId : const Uuid().v4()),
    );

    Navigator.pop(context, taskToSave);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Tarea' : 'Nueva Tarea'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveTask,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEditing ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Título
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título *',
                border: OutlineInputBorder(),
              ),
              maxLength: 200,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),

            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              initialValue: _task.description,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLength: 1000,
              maxLines: 3,
              onChanged: (v) => _task = _task.copyWith(description: v),
            ),

            const SizedBox(height: 16),

            // Prioridad
            DropdownButtonFormField<Priority>(
              value: _task.priority,
              decoration: const InputDecoration(
                labelText: 'Prioridad',
                border: OutlineInputBorder(),
              ),
              items: Priority.values.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getPriorityColor(p),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_getPriorityLabel(p)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _task = _task.copyWith(priority: v)),
            ),

            const SizedBox(height: 16),

            // Fecha y Hora
            Row(
              children: [
                Expanded(
                  child: _buildDateField(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTimeField(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Duración
            Row(
              children: [
                const Text('Duración:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                DurationSelector(
                  initialMinutes: _task.durationMinutes,
                  onChanged: (mins) {
                    setState(() {
                      _task = _task.copyWith(durationMinutes: mins);
                    });
                    _checkOverlap();
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Overlap Warning
            if (_checkingOverlap)
              const Center(child: CircularProgressIndicator())
            else if (_overlappingTasks.isNotEmpty)
              OverlapWarning(
                overlappingTasks: _overlappingTasks,
                onCreateAnyway: _saveTask,
                onChangeSchedule: () {
                  // Focus en fecha
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _task.dueDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (date != null) {
          setState(() => _task = _task.copyWith(dueDate: date));
          _checkOverlap();
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _task.dueDate != null
                  ? utils.DateUtils.formatDate(_task.dueDate!)
                  : 'Sin fecha',
            ),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField() {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _task.dueTime ??
              TimeOfDay(hour: DateTime.now().hour + 1, minute: 0),
        );
        if (time != null) {
          setState(() => _task = _task.copyWith(dueTime: time));
          _checkOverlap();
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Hora',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _task.dueTime != null
                  ? utils.DateUtils.formatTime(_task.dueTime!)
                  : 'Sin hora',
            ),
            const Icon(Icons.access_time, size: 18),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(Priority p) {
    switch (p) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.amber;
      case Priority.low:
        return Colors.green;
    }
  }

  String _getPriorityLabel(Priority p) {
    switch (p) {
      case Priority.high:
        return 'Alta';
      case Priority.medium:
        return 'Media';
      case Priority.low:
        return 'Baja';
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "$(cat <<'EOF'
feat: task form screen completo

- Create/Edit con validación de título
- Selectores de fecha y hora
- DurationSelector con stepper
- Integración de OverlapWarning
- Priority dropdown con colores

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)" && git push
```

---

## Task 8: TaskCard con duración y dependencias

**Files:**
- Modify: `lib/widgets/task_card.dart` — mostrar duración, candado y categorías

- [ ] **Step 1: Crear lib/widgets/task_card.dart completo**

```dart
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/date_utils.dart' as utils;

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBlocked = task.dependsOnTaskId != null && !task.isCompleted;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: isBlocked ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Checkbox o candado
                _buildLeading(),
                const SizedBox(width: 12),

                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título y prioridad
                      Row(
                        children: [
                          if (task.priority == Priority.high)
                            Container(
                              width: 4,
                              height: 16,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Metadata: fecha, hora, duración
                      if (task.dueDate != null || task.durationMinutes != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              if (task.dueDate != null) ...[
                                Icon(
                                  Icons.event,
                                  size: 14,
                                  color: _getDateColor(),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  utils.DateUtils.getRelativeDate(task.dueDate!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getDateColor(),
                                  ),
                                ),
                              ],
                              if (task.dueTime != null) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                const SizedBox(width: 2),
                                Text(
                                  utils.DateUtils.formatTime(task.dueTime!),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                              if (task.durationMinutes != null) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 2),
                                Text(
                                  task.formattedDuration,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Categoría chip
                if (task.category != null) _buildCategoryChip(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading() {
    if (task.dependsOnTaskId != null && !task.isCompleted) {
      return const Icon(Icons.lock, size: 24, color: Colors.grey);
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: task.isCompleted ? Colors.green : Colors.grey,
          width: 2,
        ),
        color: task.isCompleted ? Colors.green : Colors.transparent,
      ),
      child: task.isCompleted
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }

  Widget _buildCategoryChip() {
    final color = _getCategoryColor(task.category!);
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        _getCategoryLabel(task.category!),
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }

  Color _getDateColor() {
    if (task.isCompleted) return Colors.grey;
    if (task.dueDate == null) return Colors.grey;
    final now = DateTime.now();
    if (task.dueDate!.isBefore(DateTime(now.year, now.month, now.day))) {
      return Colors.red;
    }
    return Colors.blue;
  }

  Color _getCategoryColor(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.work:
        return Colors.blue;
      case TaskCategory.home:
        return Colors.brown;
      case TaskCategory.health:
        return Colors.red;
      case TaskCategory.sport:
        return Colors.green;
      case TaskCategory.personal:
        return Colors.purple;
      case TaskCategory.study:
        return Colors.orange;
      case TaskCategory.shopping:
        return Colors.pink;
      case TaskCategory.finance:
        return Colors.teal;
    }
  }

  String _getCategoryLabel(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.work:
        return 'Trabajo';
      case TaskCategory.home:
        return 'Casa';
      case TaskCategory.health:
        return 'Salud';
      case TaskCategory.sport:
        return 'Deporte';
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.study:
        return 'Estudio';
      case TaskCategory.shopping:
        return 'Compras';
      case TaskCategory.finance:
        return 'Finanzas';
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "$(cat <<'EOF'
feat: task card con duración, candado y categorías

- Muestra duración con icono de reloj
- Candado para tareas bloqueadas por dependencia
- Chip de categoría con color
- Fecha en rojo si vencida
- Línea en título si completada

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)" && git push
```

---

## Self-Review

1. **Spec coverage:**
   - Modificación 1 (duración): ✅ Tasks 2, 7, 8
   - Modificación 2 (superposición): ✅ Tasks 5, 7
   - Modificación 3 (eliminar recurrente): ✅ Task 4
   - Modificación 4 (auto-limpieza): ✅ Task 3

2. **Placeholder scan:** Sin TBD/TODO en el plan. Cada paso tiene código concreto.

3. **Type consistency:**
   - `Task.recurrencePatternId` usado consistentemente como `String?`
   - `Task.durationMinutes` usado como `int?`
   - `RecurrenceType.none` (enum, no `0`)
   - `TimeOfDay` importado de `flutter/material.dart`
   - `TimeOfDay` helper en database_helper creado localmente para evitar conflicto

---

**Plan complete and saved to `docs/superpowers/plans/2026-03-31-tasktracker-implementation.md`.**

Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
