import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/duration_selector.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  late int? _durationMinutes;

  @override
  void initState() {
    super.initState();
    _durationMinutes = widget.task?.durationMinutes;
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
            const Text('Duracion'),
            const SizedBox(height: 8),
            DurationSelector(
              initialMinutes: _durationMinutes,
              onChanged: (minutes) {
                setState(() {
                  _durationMinutes = minutes;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}