import 'package:flutter/material.dart';
import '../data/task_repository.dart';
import '../models/task.dart';
import '../services/recurrence_service.dart';
import '../widgets/delete_recurring_dialog.dart';
import '../widgets/task_card.dart';
import '../data/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskRepository _taskRepository = TaskRepository(DatabaseHelper.instance);
  final RecurrenceService _recurrenceService = RecurrenceService();
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await _taskRepository.getAllTasks();
    setState(() {
      _tasks = tasks.where((t) => t.parentTaskId == null).toList();
      _isLoading = false;
    });
  }

  Future<void> _deleteTask(Task task) async {
    final hasRecurrence = task.recurrenceType != RecurrenceType.none &&
        task.recurrencePatternId != null;

    if (hasRecurrence) {
      final futureCount = await _taskRepository.countFutureRecurrences(
        task.recurrencePatternId!,
        task.id,
      );

      if (!mounted) return;

      final result = await showDialog<DeleteRecurrenceChoice>(
        context: context,
        builder: (context) => DeleteRecurringDialog(
          task: task,
          futureCount: futureCount,
        ),
      );

      if (result == null) return;

      if (result == DeleteRecurrenceChoice.thisOccurrence) {
        // Delete current task and create next occurrence
        final nextDueDate = _recurrenceService.calculateNextOccurrence(task);

        await _taskRepository.deleteTask(task.id);

        // Create next occurrence
        await _taskRepository.createTask(
          title: task.title,
          description: task.description,
          dueDate: nextDueDate,
          dueTime: task.dueTime,
          priority: task.priority,
          recurrenceType: task.recurrenceType,
          recurrencePatternId: task.recurrencePatternId,
          durationMinutes: task.durationMinutes,
          tagIds: task.tagIds,
        );
      } else {
        // Delete all future recurrences
        await _taskRepository.deleteFutureRecurrences(
          task.recurrencePatternId!,
          task.id,
        );
      }
    } else {
      await _taskRepository.deleteTask(task.id);
    }

    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskTracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? const Center(child: Text('No hay tareas'))
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return TaskCard(
                      task: task,
                      onDelete: () => _deleteTask(task),
                      onToggleComplete: () async {
                        await _taskRepository.toggleComplete(task.id);
                        _loadTasks();
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to task form
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}