import 'package:flutter/material.dart';
import '../models/task.dart';

enum DeleteRecurrenceChoice { thisOccurrence, allFuture }

class DeleteRecurringDialog extends StatefulWidget {
  final Task task;
  final int futureCount;

  const DeleteRecurringDialog({
    super.key,
    required this.task,
    required this.futureCount,
  });

  @override
  State<DeleteRecurringDialog> createState() => _DeleteRecurringDialogState();
}

class _DeleteRecurringDialogState extends State<DeleteRecurringDialog> {
  DeleteRecurrenceChoice _choice = DeleteRecurrenceChoice.thisOccurrence;

  String _formatDate(DateTime date) {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.task.dueDate != null ? _formatDate(widget.task.dueDate!) : '';

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.delete_outline, size: 24),
          SizedBox(width: 8),
          Text('Eliminar tarea recurrente'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${widget.task.title}" — ${_getRecurrenceText(widget.task)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          const Text('¿Qué querés eliminar?'),
          const SizedBox(height: 8),
          RadioGroup<DeleteRecurrenceChoice>(
            groupValue: _choice,
            onChanged: (value) => setState(() => _choice = value!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<DeleteRecurrenceChoice>(
                  title: const Text('Solo esta repetición'),
                  subtitle: Text('"${widget.task.title} - $dateStr"'),
                  value: DeleteRecurrenceChoice.thisOccurrence,
                ),
                RadioListTile<DeleteRecurrenceChoice>(
                  title: Text('Todas las futuras (${widget.futureCount} tareas)'),
                  subtitle: Text('Desde el $dateStr en adelante'),
                  value: DeleteRecurrenceChoice.allFuture,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_choice),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }

  String _getRecurrenceText(Task task) {
    switch (task.recurrenceType) {
      case RecurrenceType.daily:
        return 'Cada día';
      case RecurrenceType.weekly:
        return 'Semanalmente';
      case RecurrenceType.monthly:
        return 'Cada mes';
      case RecurrenceType.yearly:
        return 'Cada año';
      case RecurrenceType.none:
        return '';
    }
  }
}
