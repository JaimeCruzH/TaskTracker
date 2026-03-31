import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../data/database_helper.dart';
import '../widgets/duration_selector.dart';
import '../widgets/overlap_warning.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  late int? _durationMinutes;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<Task> _overlappingTasks = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _durationMinutes = widget.task?.durationMinutes;
    _selectedDate = widget.task?.dueDate ?? DateTime.now();
    _selectedTime = widget.task?.dueTime;
    _checkOverlap();
  }

  @override
  void dispose() {
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
      time: _selectedTime!,
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
    });
    _scheduleOverlapCheck();
  }

  void _onTimeChanged(TimeOfDay? time) {
    setState(() {
      _selectedTime = time;
    });
    _scheduleOverlapCheck();
  }

  void _onDurationChanged(int? minutes) {
    setState(() {
      _durationMinutes = minutes;
    });
    _scheduleOverlapCheck();
  }

  void _onCreateAnyway() {
    // Proceed with task creation even with overlap warning
    Navigator.of(context).pop('create');
  }

  void _onChangeSchedule() {
    // Let user change the schedule - pop with different result
    Navigator.of(context).pop('reschedule');
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date selector
            const Text('Fecha'),
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

            // Time selector
            const Text('Hora'),
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

            // Duration selector
            const Text('Duracion'),
            const SizedBox(height: 8),
            DurationSelector(
              initialMinutes: _durationMinutes,
              onChanged: _onDurationChanged,
            ),

            // Overlap warning
            if (_overlappingTasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              OverlapWarning(
                overlappingTasks: _overlappingTasks,
                onCreateAnyway: _onCreateAnyway,
                onChangeSchedule: _onChangeSchedule,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
