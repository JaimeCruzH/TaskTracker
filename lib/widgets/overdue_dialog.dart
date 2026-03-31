import 'package:flutter/material.dart';

class OverdueDialog extends StatelessWidget {
  final int overdueCount;
  final VoidCallback onViewTasks;
  final VoidCallback onDismiss;

  const OverdueDialog({
    super.key,
    required this.overdueCount,
    required this.onViewTasks,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tareas vencidas'),
      content: Text('Tienes $overdueCount tarea(s) vencida(s).'),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('Ignorar'),
        ),
        TextButton(
          onPressed: onViewTasks,
          child: const Text('Ver tareas'),
        ),
      ],
    );
  }
}