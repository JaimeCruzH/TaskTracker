# Arquitectura de TaskTracker

## Visión General

TaskTracker sigue una arquitectura **MVVM simplificada** con un **Repository Pattern** para separar la lógica de datos de la UI.

```
┌─────────────────────────────────────────────────────────────┐
│                        UI LAYER                              │
│  ┌─────────────────┐         ┌─────────────────────────┐   │
│  │   HomeScreen    │         │   TaskFormScreen         │   │
│  │  (Lista tareas) │         │   (Crear/Editar)         │   │
│  └────────┬────────┘         └────────────┬────────────┘   │
│           │                               │                  │
│           └───────────┬───────────────────┘                  │
│                       │                                      │
│                  ┌────▼────┐                                 │
│                  │ViewModel│  (TaskViewModel)                │
│                  │(State)  │                                 │
│                  └────┬────┘                                 │
└───────────────────────┼───────────────────────────────────────┘
                        │
┌───────────────────────┼───────────────────────────────────────┐
│           DOMAIN LAYER │                                       │
│                       ▼                                       │
│         ┌─────────────────────────┐                           │
│         │    TaskRepository      │  (Interfaz abstracta)     │
│         └────────────┬────────────┘                           │
│                      │                                        │
│    ┌─────────────────┼─────────────────┐                      │
│    │                 │                 │                      │
│    ▼                 ▼                 ▼                      │
│ ┌────────┐    ┌──────────────┐    ┌─────────────┐             │
│ │UseCases│    │RecurrenceSvc │    │NotificationSvc│          │
│ │(CRUD)  │    │(Próxima fecha)│   │(Alertas)     │          │
│ └────────┘    └──────────────┘    └─────────────┘             │
└───────────────────────────────────────────────────────────────┘
                        │
┌───────────────────────┼───────────────────────────────────────┐
│           DATA LAYER  │                                       │
│                       ▼                                       │
│         ┌─────────────────────────┐                           │
│         │   DatabaseHelper        │  (SQLite via sqflite)     │
│         │   - TaskDao             │                           │
│         │   - AppDatabase          │                           │
│         └─────────────────────────┘                           │
│                                                               │
│  ┌─────────┐  ┌────────────┐  ┌──────────────┐               │
│  │ Android │  │ Android    │  │ Android      │               │
│  │ System  │  │ AlarmMgr   │  │ NotificationMgr│              │
│  └─────────┘  └────────────┘  └──────────────┘               │
└───────────────────────────────────────────────────────────────┘
```

---

## Capas

### 1. UI Layer (screens/, widgets/)

**Responsabilidad:** Renderizar la interfaz y capturar interacciones del usuario.

**Componentes:**
- `HomeScreen` - Lista principal con tareas agrupadas
- `TaskFormScreen` - Formulario para crear/editar tareas
- `TaskCard` - Widget para mostrar una tarea individual
- `OverdueDialog` - Dialog cuando una tarea vence

**Estado:** Flutter `StatefulWidget` con `StateFlow` en el ViewModel.

### 2. Domain Layer (models/, services/, data/)

**Responsabilidad:** Lógica de negocio y operaciones de datos.

**Componentes:**

| Componente | Responsabilidad |
|------------|-----------------|
| `Task` (model) | Estructura de datos de tarea |
| `TaskRepository` | Interfaz abstracta CRUD |
| `TaskRepositoryImpl` | Implementación con SQLite |
| `RecurrenceService` | Calcular próximas fechas de recurrencia |
| `NotificationService` | Agendar y mostrar notificaciones |

### 3. Data Layer (data/)

**Responsabilidad:** Acceso directo a SQLite.

**Componentes:**
- `DatabaseHelper` - Conexión y operaciones CRUD
- Tabla `tasks` en SQLite

---

## Flujo de Datos

### Crear Tarea

```
Usuario toca FAB
        │
        ▼
TaskFormScreen se abre
        │
Usuario llena campos y toca "Crear"
        │
        ▼
ViewModel.createTask(task)
        │
        ├─► TaskRepository.insert(task)
        │           │
        │           ▼
        │    DatabaseHelper.insert()
        │           │
        │           ▼
        │    SQLite: tasks table
        │
        ├─► RecurrenceService.calculateNextOccurrence() (si aplica)
        │
        └─► NotificationService.schedule() (si tiene fecha)
                    │
                    ▼
            Android: AlarmManager + NotificationManager
```

### Completar Tarea Recurrente

```
Usuario hace swipe izquierda en tarea
        │
        ▼
ViewModel.completeTask(task.id)
        │
        ├─► TaskRepository.update(task.copyWith(isCompleted: true))
        │           │
        │           ▼
        │    DatabaseHelper.update()
        │
        └─► ¿Tiene recurrencia?
            │
            ├─ NO: fin
            │
            └─ SÍ:
                │
                ├─► RecurrenceService.calculateNextOccurrence(task)
                │           │
                │           ▼
                │    newDueDate = próxima fecha
                │
                ├─► TaskRepository.insert(newTask)
                │           │
                │           ▼
                │    DatabaseHelper.insert()
                │
                └─► NotificationService.schedule(newTask)
                            │
                            ▼
                    Nueva notificación agendada
```

### Mostrar Notificación

```
AlarmManager despierta en dueDate + dueTime
        │
        ▼
NotificationService.showNotification()
        │
        ▼
Android NotificationManager muestra notification
        │
        ▼
Usuario toca notification
        │
        ▼
App se abre → HomeScreen
        │
        ▼
OverdueDialog se muestra
        │
        ▼
Usuario elige: Reprogramar / Completar / Descartar
```

---

## Diagrama de Estados

```
                    ┌──────────────┐
                    │    START     │
                    └──────┬───────┘
                           │
                           ▼
              ┌────────────────────────┐
              │   App Launched        │
              │   (HomeScreen)        │
              └──────────┬───────────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
    ┌──────────┐  ┌───────────┐  ┌──────────┐
    │No Tasks  │  │With Tasks │  │ Overdue  │
    │  Empty   │  │  Loading  │  │  Exists  │
    │  State   │  └─────┬─────┘  └────┬─────┘
    └──────────┘        │             │
                        │             ▼
                        │    ┌───────────────┐
                        │    │ OverdueDialog │
                        │    │  (Modal)      │
                        │    └───────┬───────┘
                        │            │
                        │    ┌───────┼───────┐
                        │    │       │       │
                        ▼    ▼       ▼       ▼
                   [Reprogramar][Completar][Descartar]
```

---

## Dependencias Externas

```
flutter_local_notifications
        │
        ├──► Android: NotificationManager, AlarmManager
        ├──► iOS: UserNotifications
        └──► Platform channels (Dart ↔ Native)

sqflite
        │
        └──► Android: SQLite via android.database.sqlite
        └──► iOS: SQLite via FMDB

timezone
        │
        └──► Para calcular zonas horarias locales
```

---

## Consideraciones de Performance

1. **Lazy Loading:** Solo cargar tareas visibles en `LazyColumn`
2. **Pagination:** Limitar a 20 tareas por grupo
3. **Index en DB:** `dueDate`, `isCompleted`, `dependsOnTaskId`
4. **Debounce:** En búsqueda, 300ms de debounce antes de filtrar
