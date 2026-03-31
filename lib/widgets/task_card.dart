import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title),
            if (task.description != null) ...[
              const SizedBox(height: 8),
              Text(task.description!),
            ],
            if (task.dueTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(task.dueTime.toString()),
                  if (task.durationMinutes != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.timer, size: 16),
                    const SizedBox(width: 4),
                    Text(task.formattedDuration),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}