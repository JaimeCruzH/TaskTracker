import 'package:flutter/material.dart';
import '../models/task.dart';

class OverlapWarning extends StatelessWidget {
  final List<Task> overlappingTasks;
  final VoidCallback onCreateAnyway;
  final VoidCallback onChangeSchedule;

  const OverlapWarning({
    super.key,
    required this.overlappingTasks,
    required this.onCreateAnyway,
    required this.onChangeSchedule,
  });

  String _formatTaskInfo(Task task) {
    final buffer = StringBuffer();
    buffer.write('"${task.title}"');

    if (task.dueDate != null) {
      buffer.write(' — ${_formatDate(task.dueDate!)}');
    }

    if (task.dueTime != null) {
      buffer.write(' ${task.dueTime!.hour.toString().padLeft(2, '0')}:${task.dueTime!.minute.toString().padLeft(2, '0')}');
    }

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Hoy';
    } else if (taskDate == tomorrow) {
      return 'Manana';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Esta tarea se superpone con:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...overlappingTasks.map((task) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTaskInfo(task),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (task.durationMinutes != null)
                  Text(
                    'Duracion: ${task.formattedDuration}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCreateAnyway,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber.shade900,
                    side: BorderSide(color: Colors.amber.shade700),
                  ),
                  child: const Text('Crear igual'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onChangeSchedule,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Cambiar horario'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
