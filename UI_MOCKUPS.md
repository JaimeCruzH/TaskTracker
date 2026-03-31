# Mockups UI - TaskTracker

## 1. Pantalla Principal (HomeScreen)

```
┌─────────────────────────────────────┐
│ ≡  Tareas              [Trabajo ▼] │  ← AppBar + filtro categoría
├─────────────────────────────────────┤
│                                     │
│ ── HOY ──────────────────────────  │  ← Header grupo
│                                     │
│ ┌──────────────────┬──────────────┐ │
│ │ ● │ Comprar leche [🛒]   │ 3:00 PM│ │  ← TaskCard (Media)
│ │   │ Supermercado       │        │ │     con [🛒] chip categoría
│ │   │ 🔔                 │        │ │
│ └──────────────────┴──────────────┘ │
│                                     │
│ ┌──────────────────┬──────────────┐ │
│ │ ● │ Llamar a mamá [👤] │ Mañana │ │  ← TaskCard (Personal)
│ │   │                     │        │ │
│ └──────────────────┴──────────────┘ │
│                                     │
│ ── ESTA SEMANA ───────────────────  │
│                                     │
│ ┌──────────────────┬──────────────┐ │
│ │🔴│ Revisar informe    │ Vie 5PM │ │  ← TaskCard (Alta)
│ │  │ Задача      │ 🔁   │        │ │     con 🔁 (recurrente)
│ └──────────────────┴──────────────┘ │
│                                     │
│ ── BLOQUEADAS ─────────────────────  │
│                                     │
│ ┌──────────────────┬──────────────┐ │
│ │🔒 │ Presentar proyecto │ Jue │ │  ← TaskCard bloqueada
│ │   │ (esperando: Comprar   │     │ │     (opacidad 50%)
│ │   │  materiales)          │     │ │
│ └──────────────────┴──────────────┘ │
│                                     │
│                                 ⊕  │  ← FAB (verde)
└─────────────────────────────────────┘

PopupMenu (⋮):
┌────────────┐
│ Todas      │ ← activo
│ Pendientes │
│ Completadas│
└────────────┘
```

### Detalle TaskCard

```
┌────────────────────────────────────────────────────────┐
│ [IND] │ Título de la tarea enmayúsculas│ [DATE] │
│       │ Descripción opcional (truncada) │ TIME   │
│       │ [🔔] [🔁]                        │        │
└────────────────────────────────────────────────────────┘

IND = Indicador de prioridad (4px de ancho, color izq)
  🔴 = HIGH (rojo)
  🟡 = MEDIUM (amarillo)
  🟢 = LOW (verde)

DATE/TIME = Fecha y hora (derecha)
  "Hoy" / "Mañana" / "Vie" / "1 Mar"

[CAT] = Chip de categoría (color de la categoría)
  🛒 Compras | 💼 Trabajo | 🏠 Casa | etc.

Icons opcionales:
  🔔 = Notificación activada
  🔁 = Recurrente
  🔒 = Bloqueada (además de opacidad 50%)

Filtro categoría (AppBar):
┌──────────────────────────┐
│ [Todas ▼]               │ ← Dropdown
│ 💼 Trabajo              │
│ 🏠 Casa                 │
│ ❤️ Salud                │
│ 🏃 Deporte              │
│ 👤 Personal             │
│ 📚 Estudio              │
│ 🛒 Compras               │
│ 💰 Finanzas             │
└──────────────────────────┘
```

---

## 2. Formulario Crear/Editar Tarea (TaskFormScreen)

```
┌─────────────────────────────────────┐
│ ←  Nueva Tarea                 💾   │  ← AppBar (back + save)
├─────────────────────────────────────┤
│                                     │
│  Título *                            │
│  ┌─────────────────────────────┐    │
│  │ Ingresa el título...        │    │
│  └─────────────────────────────┘    │
│                                     │
│  Descripción                        │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │                             │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  Prioridad                          │
│  ┌───────┐ ┌───────┐ ┌───────┐     │
│  │  🔴   │ │  🟡   │ │  🟢   │     │
│  │ Alta  │ │ Media │ │ Baja  │     │
│  └───────┘ └───────┘ └───────┘     │
│                                     │
│  Categoría                          │
│  ┌─────────────────────────────┐    │
│  │ Sin categoría              ▼│    │
│  └─────────────────────────────┘    │
│  → 💼 Trabajo | 🏠 Casa | ❤️ Salud │
│    🏃 Deporte | 👤 Personal | 📚    │
│    🛒 Compras | 💰 Finanzas        │
│                                     │
│  Fecha límite                       │
│  ┌─────────────────────────────┐    │
│  │ 📅  Hoy, 30 Mar            ▼│    │
│  └─────────────────────────────┘    │
│                                     │
│  Hora límite                        │
│  ┌─────────────────────────────┐    │
│  │ 🕐  3:00 PM                ▼│    │
│  └─────────────────────────────┘    │
│                                     │
│  ── Repetición ──────────────────  │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ No se repite               ▼│    │
│  └─────────────────────────────┘    │
│                                     │
│  Si "Semanal" seleccionado:
│  ┌─────────────────────────────┐    │
│  │ [L] [M] [X] [J] [V] [S] [D] │    │
│  │  ✓                   ✓     │    │  ← Lun y Vie marcados
│  └─────────────────────────────┘    │
│                                     │
│  Si "Cada X días" seleccionado:
│  ┌─────────────────────────────┐    │
│  │ Cada  │ 7 │ días            │    │
│  └─────────────────────────────┘    │
│                                     │
│  ── Dependencias ────────────────  │
│                                     │
│  Esperar a que esté lista:         │
│  ┌─────────────────────────────┐    │
│  │ Seleccionar tarea...       ▼│    │
│  └─────────────────────────────┘    │
│                                     │
│  ☑ Activar recordatorio            │
│                                     │
└─────────────────────────────────────┘
```

---

## 3. Dialog de Tarea Vencida (OverdueDialog)

```
┌─────────────────────────────────────┐
│                                     │
│            ⚠️                       │  ← Icono advertencia
│       ¡Tarea vencida!               │
│                                     │
│   ─────────────────────────────     │
│                                     │
│   "Comprar leche"                   │  ← Título de la tarea
│   Venció: Ayer 3:00 PM              │  ← Cuándo venció
│                                     │
│   ─────────────────────────────     │
│                                     │
│  ┌──────────┐  ┌──────────┐         │
│  │Reprogramar│  │Completar │   [X]  │
│  └──────────┘  └──────────┘         │
│                                     │
└─────────────────────────────────────┘

Al tocar [Reprogramar]:
┌─────────────────────────────────────┐
│        Seleccionar nueva fecha       │
│  ┌─────────────────────────────┐    │
│  │    Marzo 2026               │    │
│  │ Lu Ma Mi Ju Vi Sa Do       │    │
│  │           1  2  3  4  5  6  7│    │
│  │  8  9 10 11 12 13 14       │    │
│  │ ...                        │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 🕐  5:00 PM                ▼│    │
│  └─────────────────────────────┘    │
│  ┌────────┐  ┌────────┐           │
│  │Cancelar │  │Guardar │           │
│  └────────┘  └────────┘           │
└─────────────────────────────────────┘
```

---

## 4. Empty State

```
┌─────────────────────────────────────┐
│ ≡  Tareas                    🔍 ⋮   │
├─────────────────────────────────────┤
│                                     │
│                                     │
│                                     │
│           ✓                         │  ← Icono check grande
│                                     │
│     ¡No hay tareas pendientes!      │
│                                     │
│    Toca + para crear una            │
│                                     │
│                                     │
│                                 ⊕   │
└─────────────────────────────────────┘
```

---

## 5. Swipe Actions

```
Swipe IZQUIERDA → Completar
┌─────────────────────────────────────┐
│ ←                           ←       │
│ ┌──────────────────┬──────────────┐│
│ │ ║ Comprar leche  │ 3:00 PM│ ←  ││
│ └──────────────────┴──────────────┘│
│                              COMPLETAR (verde)
└─────────────────────────────────────┘

Swipe DERECHA → Eliminar
┌─────────────────────────────────────┐
│                          →    →    │
│ ┌──────────────────┬──────────────┐│
│ │  ║ Comprar leche │ 3:00 PM│    ││
│ └──────────────────┴──────────────┘│
│ ELIMINAR (rojo)                     │
└─────────────────────────────────────┘
```

---

## 6. Diálogo Eliminar

```
┌─────────────────────────────────────┐
│  ┌─────────────────────────────────┐│
│  │  Eliminar tarea?                ││
│  │                                 ││
│  │  "Comprar leche"                ││
│  │                                 ││
│  │  ┌────────┐  ┌────────────┐      ││
│  │  │Cancelar│  │ Eliminar   │      ││
│  │  └────────┘  └────────────┘      ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

---

## Guía de Colores

### Prioridades
| Prioridad | Color Hex | Color Name |
|-----------|-----------|------------|
| Alta | #EF5350 | Red 400 |
| Media | #FFC107 | Amber 500 |
| Baja | #66BB6A | Green 400 |

### UI General
| Elemento | Color Hex |
|----------|-----------|
| Background | #FAFAFA |
| Surface (cards) | #FFFFFF |
| Primary (FAB, buttons) | #4CAF50 |
| Text primary | #212121 |
| Text secondary | #757575 |
| Divider | #E0E0E0 |
| Overdue indicator | #FF5722 |

### Estados
| Estado | Efecto visual |
|--------|---------------|
| Normal | 100% opacity |
| Blocked | 50% opacity + 🔒 |
| Completed | ~~strikethrough~~ + dimmed |
| Overdue | Red border-left |

---

## Tipografía

| Elemento | Font | Size | Weight |
|----------|------|------|--------|
| AppBar title | Roboto | 20sp | Medium (500) |
| Group header | Roboto | 14sp | Medium (500) |
| Task title | Roboto | 16sp | Regular (400) |
| Task description | Roboto | 14sp | Regular (400) |
| Task date/time | Roboto | 12sp | Regular (400) |
| Button text | Roboto | 14sp | Medium (500) |
| Dialog title | Roboto | 18sp | Medium (500) |

---

## Animaciones

| Acción | Animación | Duración |
|--------|-----------|----------|
| Task appear | Fade in + slide up | 200ms |
| Task complete (swipe) | Slide out + fade | 150ms |
| FAB press | Scale 0.95 | 100ms |
| Dialog appear | Fade in + scale from 0.9 | 200ms |
| Checkbox toggle | Scale bounce | 150ms |
| List scroll | Physics default | - |

---

## Iconografía

| Icono | Significado |
|-------|-------------|
| ⊕ / FAB | Crear nueva tarea |
| ⋮ | Menú popup |
| 🔍 | Buscar |
| 📅 | Selector de fecha |
| 🕐 | Selector de hora |
| 🔔 | Notificación activada |
| 🔁 | Tarea recurrente |
| 🔒 | Tarea bloqueada (dependencia) |
| ⚠️ | Alerta de vencimiento |
| ✓ | Tarea completada |
| ← / → | Swipe actions |
