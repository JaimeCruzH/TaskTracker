# TaskTracker - Spec de Modificaciones

**Fecha:** 2026-03-31
**Proyecto:** TaskTracker
**Tipo:** Modificaciones a proyecto existente (fase de planificación)

---

## Resumen de Modificaciones

1. Agregar duración en minutos a cada tarea
2. Advertencia de superposición de tareas al crear/editar
3. Dialog de confirmación al eliminar tarea recurrente (solo esta vs todas)
4. Auto-limpieza de tareas completadas mayores a 30 días

---

## Modificación 1: Duración en minutos

### Modelo de datos

Se agrega campo `durationMinutes` (integer, nullable, default: null).

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| durationMinutes | Integer | No | Duración en minutos (1-1440) |

### UI - TaskFormScreen

- Nuevo campo numérico con stepper (+/- 15 min)
- Rango: 1 a 1440 minutos
- Alternativa: TimePicker simplificado que retorna minutos
- Placeholder: "Sin duración"

### UI - TaskCard

- Mostrar duración como texto: "1h 30m", "45 min", o "" si es null
- Ubicación: después de la hora, con icono de reloj (🕐)

### Validaciones

- Si se ingresa, debe ser entre 1 y 1440
- No requerido — opcional

---

## Modificación 2: Advertencia de superposición

### Detección de superposición

Se ejecuta cuando usuario selecciona/modifica `dueDate` + `dueTime` en el formulario.

**Query de conflicto:**
- Tareas individuales: `WHERE dueDate = :dueDate AND dueTime IS NOT NULL AND id != :currentId`
- Tareas recurrentes: se expanden las próximas 15 ocurrencias usando `RecurrenceService` y se comparan

**Definición de conflicto:**
Una tarea B se superpone con tarea A si:
```
A.dueDate/Time <= B.dueDate/Time < A.dueDate/Time + A.durationMinutes
```
Si A no tiene duración, se asume 30 min por defecto para el cálculo.

### UI - Warning inline en TaskFormScreen

```
┌─────────────────────────────────────────┐
│  ⚠️ Esta tarea se superpone con:        │
│                                         │
│  "Reunión de equipo" — Hoy 10:00 AM     │
│  Duración: 1h                          │
│                                         │
│  [Crear igual]  [Cambiar horario →]    │
└─────────────────────────────────────────┘
```

- Aparece debajo del selector de fecha/hora cuando hay conflicto
- "Cambiar horario →" enfoca el campo de fecha/hora
- Si hay múltiples superposiciones, se listan todas
- Se recalcula con debounce de 300ms al cambiar fecha/hora

### Comportamiento

- Usuario puede crear igual si quiere (el warning es informativo, no bloqueante)
- La tarea se guarda normalmente aunque haya superposición

---

## Modificación 3: Eliminar tarea recurrente

### Nuevo campo en modelo

Se agrega `recurrencePatternId` (string, nullable) a Task.

- Todas las tareas generadas por el mismo patrón comparten el mismo `recurrencePatternId`
- Es un UUID generado al crear el patrón original

### Dialog al eliminar tarea con recurrencia

```
┌─────────────────────────────────────────┐
│     🗑️ Eliminar tarea recurrente        │
│                                         │
│  "Gym" — Cada Lunes y Jueves           │
│                                         │
│  ¿Qué querés eliminar?                 │
│                                         │
│  ○ Solo esta repetición                 │
│    "Gym - Lunes 30/marzo"              │
│                                         │
│  ○ Todas las futuras (15 tareas)        │
│    Desde el 30/marzo en adelante       │
│                                         │
│         [Cancelar]  [Eliminar]          │
└─────────────────────────────────────────┘
```

- El conteo "15 tareas" se calcula con `COUNT(*)` donde `dueDate >= hoy AND recurrencePatternId = :patternId AND id != :currentId`
- Se recalcula en tiempo real al abrir el dialog

### Comportamiento: Solo esta repetición

1. Eliminar la tarea actual (`DELETE FROM tasks WHERE id = :id`)
2. Calcular próxima ocurrencia del patrón usando `RecurrenceService`
3. Crear nueva tarea con próxima fecha, mismo `recurrencePatternId`
4. Agendar notificación para la nueva tarea

### Comportamiento: Todas las futuras

1. Eliminar tarea actual (`DELETE FROM tasks WHERE id = :id`)
2. Eliminar todas futuras: `DELETE FROM tasks WHERE recurrencePatternId = :patternId AND dueDate >= :today`
3. No se elimina el historial pasado (tareas con `dueDate < hoy`)

---

## Modificación 4: Auto-limpieza de tareas (30 días)

### Implementación

Método en `DatabaseHelper`:

```dart
Future<void> pruneOldCompletedTasks({int daysToKeep = 30}) async {
  final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
  await db.delete(
    'tasks',
    where: 'isCompleted = 1 AND createdAt < ?',
    whereArgs: [cutoffDate.toIso8601String()],
  );
}
```

### Ejecución

- **Al iniciar la app:** en `main.dart`, antes de `runApp()`
- **Opcional:** cada vez que se completa una tarea (mantiene DB limpia progresivamente)

### Nota importante

- Solo se eliminan tareas **completadas**
- Las tareas vencidas no completadas **NO se eliminan** — el usuario debe decidir qué hacer con ellas
- Tareas completadas con menos de 30 días se preservan

---

## Archivos a modificar

| Archivo | Cambios |
|---------|---------|
| `lib/models/task.dart` | Agregar `durationMinutes`, `recurrencePatternId` |
| `lib/data/database_helper.dart` | Agregar `pruneOldCompletedTasks()`, query de superposición |
| `lib/data/task_repository.dart` | Agregar métodos de recurrencia y limpieza |
| `lib/services/recurrence_service.dart` | Expansión de fechas recurrentes para detección de conflictos |
| `lib/screens/task_form_screen.dart` | Campo duración, warning inline de superposición |
| `lib/widgets/task_card.dart` | Mostrar duración |
| `lib/widgets/overdue_dialog.dart` | Dialog de confirmar eliminación |
| `lib/main.dart` | Llamar `pruneOldCompletedTasks()` al inicio |

---

## Orden de implementación sugerido

1. **Modificación 1** (duración) — Más simple, afecta solo modelo y UI básica
2. **Modificación 4** (auto-limpieza) — Se puede implementar en background sin afectar UX
3. **Modificación 3** (eliminar recurrente) — Requiere `recurrencePatternId`
4. **Modificación 2** (superposición) — Más compleja, depende de recurrence expansion
