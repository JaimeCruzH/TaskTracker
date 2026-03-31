# TaskTracker 📱

Una aplicación simple y hermosa para gestionar tus tareas pendientes en Android.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

---

## ✨ Características

- ✅ **Tareas simples** - Título, descripción, prioridad y fecha
- 🔁 **Tareas recurrentes** - Diaria, semanal, mensual o cada X días
- 🔗 **Tareas encadenadas** - Dependencias entre tareas
- 🔔 **Notificaciones** - Alertas con sonido cuando vencen
- 📱 **UI Moderna** - Material Design 3, hermosa y fácil de usar

---

## 🚀 Instalación

### Requisitos Previos

1. **Flutter SDK** (3.x o superior)
   - Descarga: https://flutter.dev/windows
   - Extrae en `C:\flutter`
   - Agrega `C:\flutter\bin` al PATH de Windows

2. **Android SDK**
   - Incluido con Android Studio, o
   - Command Line Tools: https://developer.android.com/studio#command-line-tools-only

### Verificar Instalación

```bash
# Verificar Flutter
flutter doctor

# Deberías ver:
# ✓ Flutter
# ✓ Android toolchain - Android SDK
```

### Descargar el Proyecto

```bash
# Clonar o descargar el proyecto
cd task_tracker
```

### Instalar Dependencias

```bash
flutter pub get
```

### Ejecutar en Debug

```bash
# Con celular conectado via USB (con debug USB activado)
flutter run

# O iniciar emulador
flutter emulators --launch <emulator_id>
```

### Generar APK de Release

```bash
flutter build apk --release

# El APK estará en:
# build/app/outputs/flutter-apk/app-release.apk
```

---

## 📖 Cómo Usar

### Crear una Tarea

1. Toca el botón **+** (FAB verde)
2. Ingresa el **título** (obligatorio)
3. Opcional: descripción, prioridad, fecha, hora
4. Opcional: configura **recurrencia** o **dependencia**
5. Toca **Crear**

### Completar una Tarea

- **Swipe izquierda** sobre la tarea
- O **toca el círculo** al lado izquierdo

### Eliminar una Tarea

- **Swipe derecha** sobre la tarea

### Editar una Tarea

- **Toca la tarea** para abrir el formulario
- Modifica los campos
- Toca **Guardar**

### Tareas Recurrentes

1. Al crear/editar, baja a la sección **Repetir**
2. Selecciona el tipo:
   - **Diariamente**: todos los días
   - **Semanalmente**: elige los días (Lun, Mie, Vie...)
   - **Mensualmente**: elige el día del mes
   - **Cada X días**: ingresa el intervalo
3. Cuando completes la tarea, se creará automáticamente la siguiente

### Tareas Encadenadas

1. Al crear/editar, baja a la sección **Dependencias**
2. Selecciona "Esperar a que esté lista:"
3. Elige la tarea padre de la lista
4. La tarea nueva no podrá completarse hasta que la padre esté lista

### Notificaciones

1. Las notificaciones suenan cuando una tarea vence
2. Toca la notificación para ver opciones:
   - **Reprogramar**: elige nueva fecha y hora
   - **Completar**: marca como hecha
   - **Descartar**: ignora por ahora

---

## 🎨 Diseño

### Colores de Prioridad

| Prioridad | Color | Uso |
|-----------|-------|-----|
| Alta | 🔴 Rojo | Urgente, importante |
| Media | 🟡 Amarillo | Normal |
| Baja | 🟢 Verde | Puedo esperar |

### Agrupamiento

Las tareas se agrupan automáticamente:
- **Vencidas** - Pasaron la fecha y no completadas
- **Hoy** - Vencen hoy
- **Mañana** - Vencen mañana
- **Esta semana** - Próximos 7 días
- **Sin fecha** - No tienen fecha asignada
- **Completadas** - Ya hechas

---

## 🛠️ Arquitectura

```
lib/
├── main.dart                 # Entry point
├── models/
│   └── task.dart             # Modelo de datos
├── data/
│   ├── database_helper.dart  # SQLite operations
│   └── task_repository.dart  # Repository pattern
├── services/
│   ├── notification_service.dart  # Notificaciones locales
│   └── recurrence_service.dart     # Lógica de recurrencia
├── screens/
│   ├── home_screen.dart      # Lista principal
│   └── task_form_screen.dart # Crear/Editar tarea
├── widgets/
│   ├── task_card.dart        # Card de tarea
│   ├── priority_chip.dart    # Chip de prioridad
│   ├── recurrence_selector.dart  # Selector de recurrencia
│   ├── dependency_picker.dart     # Selector de dependencia
│   └── overdue_dialog.dart   # Dialog de tarea vencida
└── utils/
    └── date_utils.dart       # Helpers de fecha
```

**Patrón:** MVVM simplificado con Repository pattern

---

## 📝 Licencia

Este proyecto es open source bajo licencia MIT.

---

## 🙏 Créditos

Desarrollado con ❤️ usando Flutter
