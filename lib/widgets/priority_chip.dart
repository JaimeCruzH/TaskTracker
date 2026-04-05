import 'package:flutter/material.dart';
import '../models/task.dart';

class PriorityChip extends StatelessWidget {
  final Priority priority;
  final bool isSelected;
  final VoidCallback? onTap;

  const PriorityChip({
    super.key,
    required this.priority,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _getColor() : _getColor().withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getColor(),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          _getLabel(),
          style: TextStyle(
            color: isSelected ? Colors.white : _getColor(),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Color _getColor() {
    switch (priority) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.blue;
      case Priority.high:
        return Colors.red;
    }
  }

  String _getLabel() {
    switch (priority) {
      case Priority.low:
        return 'Baja';
      case Priority.medium:
        return 'Media';
      case Priority.high:
        return 'Alta';
    }
  }
}