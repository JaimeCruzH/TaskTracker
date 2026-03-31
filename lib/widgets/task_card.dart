import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/date_utils.dart' as utils;

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final String? parentTaskTitle;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.parentTaskTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isBlocked = task.dependsOnTaskId != null && !task.isCompleted;

    Widget cardContent = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: isBlocked ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Checkbox or lock icon
                _buildLeading(),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and priority indicator
                      Row(
                        children: [
                          if (task.priority == Priority.high)
                            Container(
                              width: 4,
                              height: 16,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Metadata: date, time, duration
                      if (task.dueDate != null || task.durationMinutes != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              if (task.dueDate != null) ...[
                                Icon(
                                  Icons.event,
                                  size: 14,
                                  color: _getDateColor(),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  utils.DateUtils.getRelativeDate(task.dueDate!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getDateColor(),
                                  ),
                                ),
                              ],
                              if (task.dueTime != null) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                const SizedBox(width: 2),
                                Text(
                                  utils.DateUtils.formatTime(task.dueTime!),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                              if (task.durationMinutes != null) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 2),
                                Text(
                                  task.formattedDuration,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Category chip
                if (task.category != null) _buildCategoryChip(),
              ],
            ),
          ),
        ),
      ),
    );

    // Add tooltip for blocked tasks
    if (isBlocked && parentTaskTitle != null) {
      cardContent = Tooltip(
        message: 'Bloqueada por: $parentTaskTitle',
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildLeading() {
    if (task.dependsOnTaskId != null && !task.isCompleted) {
      return const Icon(Icons.lock, size: 24, color: Colors.grey);
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: task.isCompleted ? Colors.green : Colors.grey,
          width: 2,
        ),
        color: task.isCompleted ? Colors.green : Colors.transparent,
      ),
      child: task.isCompleted
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }

  Widget _buildCategoryChip() {
    final color = _getCategoryColor(task.category!);
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        _getCategoryLabel(task.category!),
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }

  Color _getDateColor() {
    if (task.isCompleted) return Colors.grey;
    if (task.dueDate == null) return Colors.grey;
    final now = DateTime.now();
    if (task.dueDate!.isBefore(DateTime(now.year, now.month, now.day))) {
      return Colors.red;
    }
    return Colors.blue;
  }

  Color _getCategoryColor(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.work:
        return Colors.blue;
      case TaskCategory.home:
        return Colors.brown;
      case TaskCategory.health:
        return Colors.red;
      case TaskCategory.sport:
        return Colors.green;
      case TaskCategory.personal:
        return Colors.purple;
      case TaskCategory.study:
        return Colors.orange;
      case TaskCategory.shopping:
        return Colors.pink;
      case TaskCategory.finance:
        return Colors.teal;
    }
  }

  String _getCategoryLabel(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.work:
        return 'Trabajo';
      case TaskCategory.home:
        return 'Casa';
      case TaskCategory.health:
        return 'Salud';
      case TaskCategory.sport:
        return 'Deporte';
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.study:
        return 'Estudio';
      case TaskCategory.shopping:
        return 'Compras';
      case TaskCategory.finance:
        return 'Finanzas';
    }
  }
}