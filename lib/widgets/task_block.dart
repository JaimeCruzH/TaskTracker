import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskBlock extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskBlock({
    super.key,
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white, width: 1),
        ),
        padding: const EdgeInsets.all(4),
        child: Text(
          task.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (task.priority) {
      case Priority.high:
        return const Color(0xFFF44336); // Rojo
      case Priority.medium:
        return const Color(0xFFFF9800); // Naranja
      case Priority.low:
        return const Color(0xFF4CAF50); // Verde
    }
  }
}