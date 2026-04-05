import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../data/database_helper.dart';
import '../providers/task_repository_provider.dart';
import '../widgets/duration_selector.dart';
import '../widgets/overlap_warning.dart';
import '../widgets/recurrence_selector.dart';
import '../widgets/dependency_picker.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late Priority _priority;
  RecurrenceType _recurrenceType = RecurrenceType.none;
  late int? _durationMinutes;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _dependsOnTaskId;
  List<Task> _overlappingTasks = [];
  List<Task> _availableTasks = [];
  Timer? _debounceTimer;
  bool _isLoading = false;
  bool _showOverlapWarning = true;

  bool get _isEditMode => widget.task != null;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _initializeFields();
    _checkOverlap();
  }

  void _initializeFields() {
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _priority = widget.task!.priority;
      _recurrenceType = widget.task!.recurrenceType;
      _durationMinutes = widget.task!.durationMinutes;
      _selectedDate = widget.task!.dueDate;
      if (widget.task!.hasTime) {
        _selectedTime = TimeOfDay(hour: widget.task!.dueTimeHour!, minute: widget.task!.dueTimeMinute!);
      }
      _dependsOnTaskId = widget.task!.parentTaskId;
    } else {
      _priority = Priority.medium;
      _durationMinutes = 30;
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  Future<void> _loadTasks() async {
    final repository = Provider.of<TaskRepositoryProvider>(context, listen: false);
    await repository.loadTasks();
    final allTasks = repository.repository.groupedTasks.values.expand((tasks) => tasks).toList();
    if (mounted) {
      setState(() {
        _availableTasks = allTasks;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _scheduleOverlapCheck() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _checkOverlap();
    });
  }

  Future<void> _checkOverlap() async {
    if (_selectedDate == null || _selectedTime == null || _durationMinutes == null) {
      if (mounted) {
        setState(() {
          _overlappingTasks = [];
        });
      }
      return;
    }

    final overlapping = await DatabaseHelper.instance.findOverlappingTasks(
      date: _selectedDate!,
      timeHour: _selectedTime!.hour,
      timeMinute: _selectedTime!.minute,
      durationMinutes: _durationMinutes!,
      currentTaskId: widget.task?.id,
    );

    if (mounted) {
      setState(() {
        _overlappingTasks = overlapping;
      });
    }
  }

  void _onDateChanged(DateTime? date) {
    setState(() {
      _selectedDate = date;
      _showOverlapWarning = true;
    });
    _scheduleOverlapCheck();
  }

  void _onTimeChanged(TimeOfDay? time) {
    setState(() {
      _selectedTime = time;
      _showOverlapWarning = true;
    });
    _scheduleOverlapCheck();
  }

  void _onDurationChanged(int? minutes) {
    setState(() {
      _durationMinutes = minutes;
      _showOverlapWarning = true;
    });
    _scheduleOverlapCheck();
  }

  void _onCreateAnyway() {
    _saveTask(skipOverlapWarning: true);
  }

  void _onChangeSchedule() {
    setState(() {
      _showOverlapWarning = false;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      _onDateChanged(picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      _onTimeChanged(picked);
    }
  }

  Future<void> _saveTask({bool skipOverlapWarning = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!skipOverlapWarning && _overlappingTasks.isNotEmpty) {
      return; // User needs to acknowledge overlap warning first
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = Provider.of<TaskRepositoryProvider>(context, listen: false);

      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();

      if (_isEditMode) {
        final updatedTask = widget.task!.copyWith(
          title: title,
          description: description.isNotEmpty ? description : null,
          priority: _priority,
          dueDate: _selectedDate,
          dueTimeHour: _selectedTime?.hour,
          dueTimeMinute: _selectedTime?.minute,
          durationMinutes: _durationMinutes,
          recurrenceType: _recurrenceType,
          parentTaskId: _dependsOnTaskId,
        );
        await repository.repository.updateTask(updatedTask);
        if (mounted) {
          Navigator.of(context).pop(updatedTask);
        }
      } else {
        final newTask = await repository.repository.createTask(
          title: title,
          description: description.isNotEmpty ? description : null,
          priority: _priority,
          dueDate: _selectedDate,
          dueTimeHour: _selectedTime?.hour,
          dueTimeMinute: _selectedTime?.minute,
          durationMinutes: _durationMinutes,
          recurrenceType: _recurrenceType,
          parentTaskId: _dependsOnTaskId,
        );
        if (mounted) {
          Navigator.of(context).pop(newTask);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Tarea' : 'Nueva Tarea'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveTask,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titulo
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titulo *',
                  hintText: 'Ingrese el titulo de la tarea',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                maxLength: 200,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El titulo es requerido';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Descripcion
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripcion',
                  hintText: 'Ingrese una descripcion (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLength: 1000,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 16),

              // Prioridad
              DropdownButtonFormField<Priority>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Prioridad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: Priority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag,
                          color: _getPriorityColor(priority),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(_getPriorityLabel(priority)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _priority = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Fecha
              const Text(
                'Fecha',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Seleccionar fecha',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Hora
              const Text(
                'Hora',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime != null
                            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                            : 'Seleccionar hora',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Duracion
              const Text(
                'Duracion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DurationSelector(
                initialMinutes: _durationMinutes,
                onChanged: _onDurationChanged,
              ),
              const SizedBox(height: 24),

              // Recurrencia
              RecurrenceSelector(
                selectedType: _recurrenceType,
                onChanged: (type) {
                  setState(() {
                    _recurrenceType = type;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Dependencia
              const Text(
                'Dependencia de tarea padre',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DependencyPicker(
                selectedTaskId: _dependsOnTaskId,
                onChanged: (taskId) {
                  setState(() {
                    _dependsOnTaskId = taskId;
                  });
                },
                availableTasks: _availableTasks,
                currentTaskId: widget.task?.id,
              ),
              const SizedBox(height: 8),
              Text(
                'Esta tarea sera una subtarea de la tarea seleccionada',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),

              // Overlap warning
              if (_overlappingTasks.isNotEmpty && _showOverlapWarning) ...[
                const SizedBox(height: 24),
                OverlapWarning(
                  overlappingTasks: _overlappingTasks,
                  onCreateAnyway: _onCreateAnyway,
                  onChangeSchedule: _onChangeSchedule,
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  String _getPriorityLabel(Priority priority) {
    switch (priority) {
      case Priority.high:
        return 'Alta';
      case Priority.medium:
        return 'Media';
      case Priority.low:
        return 'Baja';
    }
  }
}