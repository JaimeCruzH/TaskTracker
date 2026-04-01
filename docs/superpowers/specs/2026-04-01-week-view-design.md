# TaskTracker - Spec: Vista de Semana

**Fecha:** 2026-04-01
**Proyecto:** TaskTracker
**Tipo:** Nueva funcionalidad

---

## Resumen

Agregar una vista de semana al HomeScreen que muestra las tareas de cada día como bloques de colores posicionados según su hora de inicio y duración.

---

## Navegación

- HomeScreen con TabBar: tabs "Lista" y "Semana"
- Estado persiste al alternar entre tabs
- Tab "Lista" = vista actual, Tab "Semana" = nueva vista

---

## Layout de la Semana

### Header de columnas (7 columnas)
```
┌──────────────────────────────────────────────────────┐
│  Lista  │  Semana                                     │
├──────────────────────────────────────────────────────┤
│         Lun  Mar  Mié  Jue  Vie  Sáb  Dom          │
│          30   31    1   2    3    4    5   ← header │
└──────────────────────────────────────────────────────┘
```

### Body: 7 columnas (una por día)
- Cada columna tiene scroll interno si las tareas exceden el viewport
- La columna del día de hoy tiene highlight de fondo (color primario suave)

### Estructura de cada columna (de arriba hacia abajo):

1. **Tareas sin hora** → Cards compactas (sin posición vertical específica)
2. **Línea divisoria horizontal** (si hay ambas tipos)
3. **Tareas con hora** → Bloques posicionados verticalmente según hora

```
Columna (ejemplo "Miércoles"):
┌────────────────┐
│ □ Tarea A     │  ← Card compacta (sin hora)
│ □ Tarea B     │
├────────────────┤  ← Divisor (si hay sin hora Y con hora)
│ ██ Tarea C    │  ← Bloque desde 10:00, altura = duración
│ ██ Tarea D    │  ← Bloque desde 11:00
│                │     (gap de 2px entre bloques adyacentes)
└────────────────┘
```

---

## Bloques de tarea (con hora)

### Posicionamiento vertical
- Hora inicio → posición Y proporcional dentro del día
- Altura del bloque → proporcional a durationMinutes
- Escala: 8:00 AM = top, 20:00 (8 PM) = bottom (12 horas visibles por defecto)

### Apariencia
- **Color de fondo:** Prioridad (rojo=#F44336 alta, amarillo=#FF9800 media, verde=#4CAF50 baja)
- **Texto:** Título truncado (max 2 líneas), blanco, fontsize 11
- **Borde redondeado:** 4px
- **Gap entre bloques:** 2px vertical (CRÍTICO: evita que bloques del mismo color se fusionen)
- **Separación visual:** Cada bloque tiene borde blanco de 1px (o gap de 2px) para delimitarlos claramente

### Si dos tareas tienen la misma prioridad adyacente:
- Gap de 2px entre ellos
- Borde blanco de 1px para demarcación visual clara
- NO se fusionan en un bloque continuo

### Ejemplo visual:
```
██ Tarea C (Alta, 10:00, 1h) ██
     ↑ gap 2px
███ Tarea D (Alta, 11:00, 30min) ███  ← Se ve como bloque separado, no continuo
```

---

## Tareas sin hora (cards compactas)

- Card pequeño: altura ~40px
- Muestra: título (truncado) + icono de reloj sin hora
- Color de borde izquierdo según prioridad
- Dispuestas verticalmente arriba de la columna

---

## Navegación entre semanas

- **Flechas ◀ ▶** en la AppBar de la vista semana
- **Tap en "Hoy"** → vuelve a la semana actual
- Cada cambio de semana recalcula las tareas a mostrar

---

## Interacción

### Tap en bloque de tarea
→ Abre TaskFormScreen en modo edición (editing = true) con la tarea cargada

### Tap en card compacta
→ Abre TaskFormScreen en modo edición

---

## Componentes a crear

| Componente | Descripción |
|------------|-------------|
| `week_view_screen.dart` | Pantalla completa con tabs, grid, navegación |
| `week_day_column.dart` | Una columna (un día) con sus tareas |
| `task_block.dart` | Bloque visual de tarea con hora |
| `compact_task_card.dart` | Card compacta para tarea sin hora |

---

## Tareas a modificar

| Archivo | Cambio |
|---------|--------|
| `home_screen.dart` | Agregar TabBar y WeekViewScreen |
| `main.dart` | (sin cambio) |

---

## Orden de implementación sugerido

1. `week_day_column.dart` - Una columna con lista simple de tareas
2. `task_block.dart` - Bloque visual posicionado
3. `compact_task_card.dart` - Card para sin hora
4. `week_view_screen.dart` - Ensamblar todo con grid
5. `home_screen.dart` - Agregar tabs y navegación
