import 'package:flutter/material.dart';
import '../models/task.dart';
import 'task_block.dart';
import 'compact_task_card.dart';

class WeekDayColumn extends StatelessWidget {
  final DateTime date;
  final List<Task> tasks;
  final bool isToday;
  final Function(Task) onTaskTap;

  const WeekDayColumn({
    super.key,
    required this.date,
    required this.tasks,
    required this.isToday,
    required this.onTaskTap,
  });

  // Horas visibles: 8:00 (top) a 20:00 (bottom) = 12 horas
  static const double startHour = 8.0;
  static const double pixelsPerHour = 40.0;

  @override
  Widget build(BuildContext context) {
    final tasksWithTime = tasks.where((t) => t.dueTime != null).toList()
      ..sort((a, b) => _timeToMinutes(a.dueTime!).compareTo(_timeToMinutes(b.dueTime!)));
    final tasksWithoutTime = tasks.where((t) => t.dueTime == null).toList();

    return Container(
      decoration: BoxDecoration(
        color: isToday ? Colors.blue.shade50 : Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(
                  _getDayName(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.blue : Colors.grey,
                  ),
                ),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday ? Colors.blue : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Lista de tareas con hora posicionadas
          Expanded(
            child: Stack(
              children: [
                // Líneas de hora (background visual)
                ...List.generate(13, (i) {
                  return Positioned(
                    top: i * pixelsPerHour,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                  );
                }),

                // Bloques de tareas posicionados
                ...tasksWithTime.asMap().entries.map((entry) {
                  final index = entry.key;
                  final task = entry.value;
                  return _buildPositionedTask(task, index, tasksWithTime);
                }),
              ],
            ),
          ),

          // Tareas sin hora (abajo)
          if (tasksWithoutTime.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                itemCount: tasksWithoutTime.length,
                itemBuilder: (context, index) {
                  return CompactTaskCard(
                    task: tasksWithoutTime[index],
                    onTap: () => onTaskTap(tasksWithoutTime[index]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPositionedTask(Task task, int index, List<Task> allTasks) {
    final startMinutes = _timeToMinutes(task.dueTime!);
    final duration = task.durationMinutes ?? 30;
    final endMinutes = startMinutes + duration;

    // Posición Y: proporcional a minutos desde startHour
    final top = ((startMinutes - (startHour * 60).toInt()) / 60.0) * pixelsPerHour;
    // Altura: proporcional a duración (mínimo 20px)
    final height = ((duration / 60.0) * pixelsPerHour).clamp(20.0, double.infinity);

    // Calcular si hay tareas adyacentes (menos de 5 min de gap)
    bool hasAdjacentBelow = false;
    if (index < allTasks.length - 1) {
      final nextTask = allTasks[index + 1];
      final nextStart = _timeToMinutes(nextTask.dueTime!);
      hasAdjacentBelow = (nextStart - endMinutes).abs() < 5;
    }

    // Gap de 2px entre bloques adyacentes para evitar fusión visual
    final bottomMargin = hasAdjacentBelow ? 0.0 : 2.0;

    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: height,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomMargin),
        child: TaskBlock(
          task: task,
          onTap: () => onTaskTap(task),
        ),
      ),
    );
  }

  double _minutesToPixels(int minutes) {
    return (minutes / 60.0) * pixelsPerHour;
  }

  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  String _getDayName() {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[date.weekday - 1];
  }
}