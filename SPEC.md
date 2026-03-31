# TaskTracker - Especificación Técnica

## 1. Concepto y Visión

TaskTracker es una aplicación de gestión de tareas personales para Android, diseñada para ser simple, rápida y hermosa. Inspirada en Todoist pero sin la complejidad de una app enterprise. La experiencia debe sentirse ligera y satisfactorio: crear y completar tareas debe dar una sensación de progreso inmediato.

**Filosofía:** Mínimo esfuerzo para capturar una tarea, máximo poder cuando se necesita.

---

## 2. Público Objetivo

- Individuos que necesitan trackear tareas personales
- Personas que prefieren apps simples sobre feature-bloated
- Usuarios que valoran velocidad y buena UI sobre maximización de features

---

## 3. Funcionalidades

### 3.1 CRUD de Tareas

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| id | Integer | Auto | Identificador único |
| title | String | Sí | Título de la tarea (max 200 chars) |
| description | String | No | Descripción detallada (max 1000 chars) |
| priority | Enum | Sí | HIGH (rojo), MEDIUM (amarillo), LOW (verde) |
| category | Enum | No | Trabajo, Casa, Salud, Deporte, Personal, Estudio |
| dueDate | DateTime | No | Fecha límite |
| dueTime | TimeOfDay | No | Hora límite |
| isCompleted | Boolean | Sí | Si está completada |
| createdAt | DateTime | Auto | Fecha de creación |

### 3.2 Tareas Recurrentes

| Tipo | Descripción | Ejemplo |
|------|-------------|---------|
| Diaria | Todos los días | "Beber agua" cada día |
| Semanal | Días específicos de la semana | "Gym" cada Lun y Jue |
| Mensual | Día específico del mes | "Pagar arriendo" día 1 |
| CadaXDays | Cada N días | "Llamar a mamá" cada 7 días |

**Comportamiento al completar:**
1. Marcar tarea como completada
2. Si tiene recurrencia activa:
   - Calcular próxima fecha según tipo
   - Crear nueva tarea con los mismos datos (excepto id, createdAt)
   - Agendar notificación para la nueva fecha
3. Cancelar notificación de la tarea completada

### 3.3 Tareas Encadenadas (Dependencias)

- Una tarea puede tener como前提条件 otra tarea (padre)
- La tarea hija NO puede completarse si el padre no está completado
- La tarea hija se muestra con:
  - Opacidad 50%
  - Icono de candado
  - Tooltip: "Bloqueada por: [título del padre]"
- Al completar el padre, las hijas se habilitan automáticamente

**Validaciones:**
- No se puede seleccionar a sí misma como padre
- No se puede crear dependencia circular
- Solo tareas pendientes pueden ser padres

### 3.4 Notificaciones de Vencimiento

**Trigger:** Cuando `dueDate + dueTime < now` y `isCompleted == false`

**Comportamiento:**
1. Se muestra notificación en notification tray
2. Sonido de alarma (default notification sound)
3. Al tocar: abre OverdueDialog en la app

**OverdueDialog:**
```
┌─────────────────────────────────────┐
│         ⚠️ ¡Tarea vencida!          │
│                                     │
│   "Comprar leche"                  │
│   Venció: Ayer 3:00 PM             │
│                                     │
│  [Reprogramar]  [Completar]  [X]   │
└─────────────────────────────────────┘
```

**Acciones:**
- **Reprogramar:** Abre DatePicker, luego TimePicker, guarda nueva fecha, re-agenda notificación
- **Completar:** Marca completada, cancela notificación, procesa recurrencia
- **Descartar:** Cierra dialog, la tarea sigue pendiente

### 3.5 Categorías

Cada tarea puede pertenecer a una categoría para facilitar navegación y filtrado.

| Categoría | Color | Icono | Descripción |
|-----------|-------|-------|-------------|
| Trabajo | 🔵 Azul #2196F3 | 💼 | Tareas laborales y profesionales |
| Casa | 🟤 Marrón #795548 | 🏠 | Tareas del hogar |
| Salud | 🔴 Rojo #F44336 | ❤️ | Salud y bienestar |
| Deporte | 🟢 Verde #4CAF50 | 🏃 | Ejercicio y actividad física |
| Personal | 🟣 Púrpura #9C27B0 | 👤 | Tareas personales |
| Estudio | 🟡 Amarillo #FF9800 | 📚 | Educación y aprendizaje |
| Compras | 🩷 Rosa #E91E63 | 🛒 | Lista de compras |
| Finanzas | 💵 Verde oscuro #388E3C | 💰 | Dinero y cuentas |

**Comportamiento:**
- Las categorías son predefinidas (no editables por el usuario inicialmente)
- Una tarea tiene UNA categoría o ninguna (opcional)
- En la lista, las tareas muestran un chip de color con la categoría
- Se puede filtrar la lista por una o más categorías

---

## 4. Modelo de Datos

```dart
enum Priority { high, medium, low }

enum RecurrenceType { none, daily, weekly, monthly, everyXDays }

enum TaskCategory { work, home, health, sport, personal, study, shopping, finance }

class Task {
  int? id;
  String title;
  String description;
  Priority priority;
  TaskCategory category;  // nullable, default: null
  DateTime? dueDate;
  TimeOfDay? dueTime;
  bool isCompleted;
  DateTime createdAt;

  // Recurrencia
  RecurrenceType recurrence;  // default: none
  int? recurrenceInterval;    // para everyXDays
  List<int>? weeklyDays;       // 1=Lunes, 7=Domingo

  // Dependencias
  int? dependsOnTaskId;

  // Notificaciones
  bool notificationEnabled;    // default: true
  int? notificationId;         // ID de la notificación agendada
}
```

---

## 5. Estados de la UI

### Pantalla Principal (HomeScreen)

| Estado | Descripción |
|--------|-------------|
| Empty | "No hay tareas. ¡Toca + para crear una!" |
| Loading | CircularProgressIndicator centrado |
| With Tasks | Lista agrupada con headers |
| Filter Active | Muestra badge con count del filtro |

### Formulario (TaskFormScreen)

| Estado | Descripción |
|--------|-------------|
| Create | Título "Nueva Tarea", botón "Crear" |
| Edit | Título "Editar Tarea", botón "Guardar" |
| Saving | Botón deshabilitado con loading |
| Error | SnackBar con mensaje de error |

---

## 6. Reglas de Negocio

1. **Ordenamiento por defecto:**
   - Tareas pendientes: por fecha (asc), luego por prioridad (HIGH → LOW)
   - Tareas completadas: por fecha de completado (desc)

2. **Agrupamiento en lista:**
   - Vencidas (fecha < hoy y no completadas)
   - Hoy
   - Mañana
   - Esta semana (próximos 7 días)
   - Sin fecha
   - Completadas (últimas 20)

3. **Filtro por categoría:**
   - En AppBar: dropdown/chips para seleccionar categoría
   - "Todas" = sin filtro (muestra todas)
   - Al filtrar por categoría, solo muestra tareas de esa categoría

3. **Límites:**
   - Máximo 500 tareas activas
   - Máximo 20 tareas completadas en historial

4. **Alerta de tarea vencida:**
   - Solo se muestra dialog para UNA tarea a la vez
   - Se muestra la más antigua vencida primero

---

## 7. Permisos Android

| Permiso | Para qué |
|---------|----------|
| POST_NOTIFICATIONS | Mostrar notificaciones (Android 13+) |
| VIBRATE | Vibrar con la notificación |
| SCHEDULE_EXACT_ALARM | Agendar notificaciones precisas |
| RECEIVE_BOOT_COMPLETED | Re-agendar notificaciones tras reinicio |
