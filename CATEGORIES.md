# Categorías - TaskTracker

## Definición

Las categorías permiten organizar las tareas por área de la vida, facilitando la navegación y el filtrado. Son predefinidas por el sistema y no pueden ser editadas o agregadas por el usuario (v1).

---

## Lista de Categorías

| ID | Nombre | Color | Hex | Icono | Descripción |
|----|--------|-------|-----|-------|-------------|
| `work` | Trabajo | Azul | #2196F3 | 💼 | Tareas laborales y profesionales |
| `home` | Casa | Marrón | #795548 | 🏠 | Tareas del hogar y mantenimiento |
| `health` | Salud | Rojo | #F44336 | ❤️ | Salud y bienestar |
| `sport` | Deporte | Verde | #4CAF50 | 🏃 | Ejercicio y actividad física |
| `personal` | Personal | Púrpura | #9C27B0 | 👤 | Tareas personales diversas |
| `study` | Estudio | Naranja | #FF9800 | 📚 | Educación y aprendizaje |
| `shopping` | Compras | Rosa | #E91E63 | 🛒 | Listas de compras |
| `finance` | Finanzas | Verde oscuro | #388E3C | 💰 | Dinero, cuentas y administración |

---

## Diseño Visual

### Chip de Categoría

```
┌─────────────────┐
│ 💼 Trabajo      │  ← Fondo: color de categoría al 20%
│                 │  ← Texto: color de categoría
└─────────────────┘

Radio: 16px
Padding: 4px horizontal, 2px vertical
Font: 12sp, medium
```

### Paleta de Colores

```
Trabajo:    ██████  #2196F3  Blue 500
Casa:       ██████  #795548  Brown 500
Salud:      ██████  #F44336  Red 500
Deporte:    ██████  #4CAF50  Green 500
Personal:   ██████  #9C27B0  Purple 500
Estudio:    ██████  #FF9800  Orange 500
Compras:    ██████  #E91E63  Pink 500
Finanzas:   ██████  #388E3C  Green 700
```

---

## Modelo de Datos

```dart
enum TaskCategory {
  work,    // Trabajo
  home,    // Casa
  health,  // Salud
  sport,   // Deporte
  personal,// Personal
  study,   // Estudio
  shopping,// Compras
  finance, // Finanzas
}

// Helper para obtener display properties
extension TaskCategoryExtension on TaskCategory {
  String get name {
    switch (this) {
      case TaskCategory.work:     return 'Trabajo';
      case TaskCategory.home:     return 'Casa';
      case TaskCategory.health:    return 'Salud';
      case TaskCategory.sport:    return 'Deporte';
      case TaskCategory.personal:  return 'Personal';
      case TaskCategory.study:     return 'Estudio';
      case TaskCategory.shopping:  return 'Compras';
      case TaskCategory.finance:   return 'Finanzas';
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.work:     return Color(0xFF2196F3);
      case TaskCategory.home:     return Color(0xFF795548);
      case TaskCategory.health:    return Color(0xFFF44336);
      case TaskCategory.sport:    return Color(0xFF4CAF50);
      case TaskCategory.personal:  return Color(0xFF9C27B0);
      case TaskCategory.study:     return Color(0xFFFF9800);
      case TaskCategory.shopping:  return Color(0xFFE91E63);
      case TaskCategory.finance:   return Color(0xFF388E3C);
    }
  }

  String get icon {
    switch (this) {
      case TaskCategory.work:     return '💼';
      case TaskCategory.home:     return '🏠';
      case TaskCategory.health:    return '❤️';
      case TaskCategory.sport:    return '🏃';
      case TaskCategory.personal:  return '👤';
      case TaskCategory.study:     return '📚';
      case TaskCategory.shopping:  return '🛒';
      case TaskCategory.finance:   return '💰';
    }
  }
}
```

---

## Uso en UI

### Filtro en HomeScreen

La barra superior muestra un dropdown con las categorías:

```
┌─────────────────────────────────────┐
│ ≡  Tareas           [Trabajo ▼]  ⋮  │
└─────────────────────────────────────┘
                        │
                        ▼
              ┌──────────────────┐
              │ [Todas]          │  ← opción "sin filtro"
              │ 💼 Trabajo       │
              │ 🏠 Casa         │
              │ ❤️ Salud        │
              │ 🏃 Deporte      │
              │ 👤 Personal     │
              │ 📚 Estudio      │
              │ 🛒 Compras      │
              │ 💰 Finanzas     │
              └──────────────────┘
```

**Comportamiento:**
- "Todas" = muestra todas las tareas sin filtro
- Al seleccionar una categoría, filtra la lista a solo esa categoría
- El filtro se mantiene al navegar entre pantallas

### TaskCard

Cada tarea muestra un chip de categoría compacto:

```
┌─────────────────────────────────────────────┐
│ ● │ Comprar leche [🛒]          │ 3:00 PM │
│   │                              │          │
└─────────────────────────────────────────────┘
      └─ Chip: fondo rosado, texto "🛒 Compras"
```

### TaskFormScreen

Selector de categoría en el formulario:

```
Categoría
┌─────────────────────────────┐
│ Sin categoría            ▼  │  ← Default: null
└─────────────────────────────┘
```

Al tocar el dropdown:
```
┌─────────────────────────────┐
│ Sin categoría              │  ← "Ninguna" option
│ 💼 Trabajo                 │
│ 🏠 Casa                    │
│ ❤️ Salud                   │
│ 🏃 Deporte                 │
│ 👤 Personal                │
│ 📚 Estudio                 │
│ 🛒 Compras                 │
│ 💰 Finanzas                │
└─────────────────────────────┘
```

---

## SQL

```sql
-- Columna en tabla tasks
category TEXT  -- NULL, 'WORK', 'HOME', 'HEALTH', 'SPORT', 'PERSONAL', 'STUDY', 'SHOPPING', 'FINANCE'

-- Índice para filtrado rápido
CREATE INDEX idx_tasks_category ON tasks(category);

-- Query para tareas filtradas por categoría
SELECT * FROM tasks
WHERE is_completed = 0
  AND category = 'WORK'
ORDER BY due_date ASC;
```

---

## Decisiones de Diseño

1. **No editables por usuario (v1):** Simplifica el desarrollo y evita el problema de tener que administrar categorías. Si el usuario necesita más, pueden usar etiquetas (future feature).

2. **8 categorías fijas:** Balance entre organización y sobrecarga.足够 para la mayoría de casos de uso personal.

3. **Iconos emoji:** Más rápido de implementar que assets de icons, universales, y funcionan bien en Material Design.

4. **Nullable:** "Sin categoría" es válido — no toda tarea necesita una.

---

## Roadmap Futuro

| Feature | Prioridad | Notas |
|---------|-----------|-------|
| Categorías editables | Media | Permiti crear/editar/eliminar |
| Múltiples categorías | Baja | Una tarea → múltiples tags |
| Colores custom | Baja | Usuario elige color |
| Iconos seleccionables | Baja | Elegir entre emoji o iconos |
