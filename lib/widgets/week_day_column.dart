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

  @override
  Widget build(BuildContext context) {
    // Separar tareas con hora y sin hora
    final tasksWithTime = tasks.where((t) => t.dueTime != null).toList();
    final tasksWithoutTime = tasks.where((t) => t.dueTime == null).toList();

    return Container(
      decoration: BoxDecoration(
        color: isToday ? Colors.blue.shade50 : Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Header: día y fecha
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

          // Tareas sin hora (cards compactas)
          if (tasksWithoutTime.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: tasksWithoutTime.length,
                itemBuilder: (context, index) {
                  return CompactTaskCard(
                    task: tasksWithoutTime[index],
                    onTap: () => onTaskTap(tasksWithoutTime[index]),
                  );
                },
              ),
            ),

          // Tareas con hora (placeholder blocks for now)
          if (tasksWithTime.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: tasksWithTime.length,
                itemBuilder: (context, index) {
                  return Container(
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 2),
                    color: Colors.grey.shade300,
                    child: Center(
                      child: Text(
                        tasksWithTime[index].title,
                        style: const TextStyle(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _getDayName() {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[date.weekday - 1];
  }
}