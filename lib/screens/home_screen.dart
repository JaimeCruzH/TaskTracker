import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_repository_provider.dart';
import '../services/recurrence_service.dart';
import '../widgets/delete_recurring_dialog.dart';
import '../widgets/task_card.dart';
import '../widgets/week_view_screen.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecurrenceService _recurrenceService = RecurrenceService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    await context.read<TaskRepositoryProvider>().loadTasks();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleComplete(Task task) async {
    final provider = context.read<TaskRepositoryProvider>();
    await provider.repository.toggleComplete(task.id);
    await _loadTasks();
  }

  Future<void> _deleteTask(Task task) async {
    try {
      final hasRecurrence = task.recurrenceType != RecurrenceType.none &&
          task.recurrencePatternId != null;

      if (hasRecurrence) {
        final futureCount = await context
            .read<TaskRepositoryProvider>()
            .repository
            .countFutureRecurrences(
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

        final provider = context.read<TaskRepositoryProvider>();
        if (result == DeleteRecurrenceChoice.thisOccurrence) {
          // Delete current task and create next occurrence
          final nextDueDate = _recurrenceService.calculateNextOccurrence(task);

          await provider.repository.deleteTask(task.id);

          // Create next occurrence only if nextDueDate is not null
          if (nextDueDate != null) {
            await provider.repository.createTask(
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
          }
        } else {
          // Delete all future recurrences
          await provider.repository.deleteFutureRecurrences(
            task.recurrencePatternId!,
            task.id,
          );
        }
      } else {
        await context.read<TaskRepositoryProvider>().repository.deleteTask(task.id);
      }

      _loadTasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting task: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskTracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Lista'),
            Tab(text: 'Semana'),
          ],
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: TabBarView(
          children: [
            _buildTaskListView(),
            const WeekViewScreen(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const TaskFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskListView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Consumer<TaskRepositoryProvider>(
      builder: (context, provider, _) {
        final grouped = provider.groupedTasks;
        final sections = <MapEntry<String, List<Task>>>[];

        // Add non-empty sections in order
        final sectionOrder = ['Vencidas', 'Hoy', 'Mañana', 'Esta semana', 'Sin fecha', 'Completadas'];
        for (final key in sectionOrder) {
          if (grouped[key]!.isNotEmpty || key == 'Completadas') {
            sections.add(MapEntry(key, grouped[key]!));
          }
        }

        if (sections.isEmpty ||
            (sections.length == 1 && sections.first.key == 'Completadas' && sections.first.value.isEmpty)) {
          return const Center(child: Text('No hay tareas'));
        }

        return ListView.builder(
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            return _buildSection(section.key, section.value);
          },
        );
      },
    );
  }

  Widget _buildSection(String title, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...tasks.map((task) => _buildDismissibleTask(task)),
      ],
    );
  }

  Widget _buildDismissibleTask(Task task) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe left to complete
          await _toggleComplete(task);
          return false;
        } else {
          // Swipe right to delete
          await _deleteTask(task);
          return false;
        }
      },
      child: TaskCard(
        task: task,
        onDelete: () => _deleteTask(task),
        onToggleComplete: () => _toggleComplete(task),
      ),
    );
  }