# Esquema de Base de Datos - TaskTracker

## Visão Geral

TaskTracker usa **SQLite** via paquete `sqflite` para persistencia local. Es una base de datos por dispositivo, sin sincronización en la nube.

---

## Diagrama ER

```
┌─────────────────────────────────────────────────┐
│                    tasks                         │
├─────────────────────────────────────────────────┤
│ id                   INTEGER (PK, AUTOINCREMENT) │
│ title                TEXT (NOT NULL)             │
│ description          TEXT                       │
│ priority             TEXT (HIGH|MEDIUM|LOW)      │
│ category             TEXT (WORK|HOME|HEALTH|     │
│                      SPORT|PERSONAL|STUDY|      │
│                      SHOPPING|FINANCE|NULL)     │
│ due_date             INTEGER (Unix timestamp)    │
│ due_time             TEXT (HH:mm)                │
│ is_completed         INTEGER (0|1)               │
│ created_at           INTEGER (Unix timestamp)    │
│ completed_at         INTEGER (Unix timestamp)    │
│ recurrence           TEXT (NONE|DAILY|WEEKLY|    │
│                      MONTHLY|EVERYXDAYS)          │
│ recurrence_interval  INTEGER                     │
│ weekly_days          TEXT (JSON: [1,4])          │
│ next_occurrence      INTEGER (Unix timestamp)    │
│ depends_on_task_id   INTEGER (FK → tasks.id)     │
│ notification_enabled INTEGER (0|1)               │
│ notification_id      INTEGER                     │
└─────────────────────────────────────────────────┘
         │
         │  (self-referential FK)
         ▼
    ┌─────────┐
    │  tasks  │
    │  (self) │
    └─────────┘
```

---

## Tabla: tasks

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | INTEGER | PK, AUTOINCREMENT | Identificador único |
| `title` | TEXT | NOT NULL | Título de la tarea |
| `description` | TEXT | NULL | Descripción opcional |
| `priority` | TEXT | NOT NULL, DEFAULT 'MEDIUM' | 'HIGH', 'MEDIUM', 'LOW' |
| `category` | TEXT | NULL | 'WORK', 'HOME', 'HEALTH', 'SPORT', 'PERSONAL', 'STUDY', 'SHOPPING', 'FINANCE' |
| `due_date` | INTEGER | NULL | Unix timestamp de la fecha límite |
| `due_time` | TEXT | NULL | Hora en formato "HH:mm" |
| `is_completed` | INTEGER | NOT NULL, DEFAULT 0 | 0 = false, 1 = true |
| `created_at` | INTEGER | NOT NULL | Unix timestamp de creación |
| `completed_at` | INTEGER | NULL | Unix timestamp cuando se completó |
| `recurrence` | TEXT | NOT NULL, DEFAULT 'NONE' | Tipo de recurrencia |
| `recurrence_interval` | INTEGER | NULL | X días para EVERYXDAYS |
| `weekly_days` | TEXT | NULL | JSON array de días [1,4,6] |
| `next_occurrence` | INTEGER | NULL | Próxima fecha calculada |
| `depends_on_task_id` | INTEGER | NULL, FK → tasks.id | Tarea padre |
| `notification_enabled` | INTEGER | NOT NULL, DEFAULT 1 | 0 = no notificar |
| `notification_id` | INTEGER | NULL | ID para cancelar notificación |

---

## Índices

```sql
-- Para filtrar tareas pendientes rápido
CREATE INDEX idx_tasks_pending ON tasks(is_completed, due_date);

-- Para encontrar tareas bloqueadas por otra
CREATE INDEX idx_tasks_dependency ON tasks(depends_on_task_id);

-- Para buscar por fecha de creación
CREATE INDEX idx_tasks_created ON tasks(created_at);
```

---

## Enums (Valores en texto)

### priority
| Valor | Descripción |
|-------|-------------|
| `'HIGH'` | Prioridad alta (rojo) |
| `'MEDIUM'` | Prioridad media (amarillo) |
| `'LOW'` | Prioridad baja (verde) |

### recurrence
| Valor | Descripción |
|-------|-------------|
| `'NONE'` | No se repite |
| `'DAILY'` | Todos los días |
| `'WEEKLY'` | Días específicos de la semana |
| `'MONTHLY'` | Día específico del mes |
| `'EVERYXDAYS'` | Cada X días |

### weekly_days (JSON)
```json
// Días de la semana: 1=Lunes, 7=Domingo
[1, 4]  // Cada Lunes y Jueves
[2]     // Cada Martes
[1, 2, 3, 4, 5]  // Lunes a Viernes
```

---

## Queries Principales

### Obtener todas las tareas ordenadas

```sql
SELECT * FROM tasks
WHERE is_completed = 0
ORDER BY
  CASE WHEN due_date < :today THEN 0
       WHEN due_date = :today THEN 1
       WHEN due_date = :tomorrow THEN 2
       WHEN due_date < :today + 7 THEN 3
       ELSE 4 END,
  CASE priority WHEN 'HIGH' THEN 0 WHEN 'MEDIUM' THEN 1 ELSE 2 END;
```

### Obtener tareas por categoría

```sql
SELECT * FROM tasks
WHERE is_completed = 0
  AND category = :category
ORDER BY due_date ASC;
```

### Obtener tarea con su padre (para mostrar candado)

```sql
SELECT t.*, p.title as parent_title
FROM tasks t
LEFT JOIN tasks p ON t.depends_on_task_id = p.id
WHERE t.id = :taskId;
```

### Tareas vencidas no completadas

```sql
SELECT * FROM tasks
WHERE is_completed = 0
  AND due_date IS NOT NULL
  AND due_date < :now
ORDER BY due_date ASC;
```

### Tareas bloqueadas por una tarea padre

```sql
SELECT * FROM tasks
WHERE depends_on_task_id = :parentId
  AND is_completed = 0;
```

### Cancelar notificación al completar

```sql
UPDATE tasks
SET notification_id = NULL
WHERE id = :taskId;
```

---

## Migraciones

### v1 (Schema inicial)

```sql
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT NOT NULL DEFAULT 'MEDIUM',
  category TEXT,
  due_date INTEGER,
  due_time TEXT,
  is_completed INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  completed_at INTEGER,
  recurrence TEXT NOT NULL DEFAULT 'NONE',
  recurrence_interval INTEGER,
  weekly_days TEXT,
  next_occurrence INTEGER,
  depends_on_task_id INTEGER REFERENCES tasks(id),
  notification_enabled INTEGER NOT NULL DEFAULT 1,
  notification_id INTEGER
);
```

---

## Modelo Dart ↔ SQLite

```dart
// Task (Dart) → Map (SQLite)
Map<String, dynamic> toMap() => {
  'id': id,
  'title': title,
  'description': description,
  'priority': priority.name.toUpperCase(),
  'category': category?.name.toUpperCase(),
  'due_date': dueDate?.millisecondsSinceEpoch,
  'due_time': dueTime != null ? '${dueTime!.hour}:${dueTime!.minute}' : null,
  'is_completed': isCompleted ? 1 : 0,
  'created_at': createdAt.millisecondsSinceEpoch,
  'completed_at': completedAt?.millisecondsSinceEpoch,
  'recurrence': recurrence?.name.toUpperCase() ?? 'NONE',
  'recurrence_interval': recurrenceInterval,
  'weekly_days': weeklyDays != null ? jsonEncode(weeklyDays) : null,
  'next_occurrence': nextOccurrence?.millisecondsSinceEpoch,
  'depends_on_task_id': dependsOnTaskId,
  'notification_enabled': notificationEnabled ? 1 : 0,
  'notification_id': notificationId,
};

// Map (SQLite) → Task (Dart)
factory Task.fromMap(Map<String, dynamic> map) => Task(
  id: map['id'],
  title: map['title'],
  description: map['description'],
  priority: Priority.values.firstWhere(
    e => e.name.toUpperCase() == map['priority'],
    orElse: () => Priority.medium,
  ),
  category: map['category'] != null
    ? TaskCategory.values.firstWhere(
        e => e.name.toUpperCase() == map['category'],
        orElse: () => TaskCategory.personal,
      )
    : null,
  dueDate: map['due_date'] != null
    ? DateTime.fromMillisecondsSinceEpoch(map['due_date'])
    : null,
  dueTime: map['due_time'] != null
    ? TimeOfDay(
        hour: int.parse(map['due_time'].split(':')[0]),
        minute: int.parse(map['due_time'].split(':')[1]),
      )
    : null,
  isCompleted: map['is_completed'] == 1,
  createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
  completedAt: map['completed_at'] != null
    ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'])
    : null,
  recurrence: RecurrenceType.values.firstWhere(
    e => e.name.toUpperCase() == map['recurrence'],
    orElse: () => RecurrenceType.none,
  ),
  recurrenceInterval: map['recurrence_interval'],
  weeklyDays: map['weekly_days'] != null
    ? List<int>.from(jsonDecode(map['weekly_days']))
    : null,
  nextOccurrence: map['next_occurrence'] != null
    ? DateTime.fromMillisecondsSinceEpoch(map['next_occurrence'])
    : null,
  dependsOnTaskId: map['depends_on_task_id'],
  notificationEnabled: map['notification_enabled'] == 1,
  notificationId: map['notification_id'],
);
```
