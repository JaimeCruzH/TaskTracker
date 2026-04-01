import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/task_repository.dart';
import '../models/task.dart';
import 'week_day_column.dart';
import '../screens/task_form_screen.dart';

class WeekViewScreen extends StatefulWidget {
  const WeekViewScreen({super.key});

  @override
  State<WeekViewScreen> createState() => _WeekViewScreenState();
}

class _WeekViewScreenState extends State<WeekViewScreen> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(DateTime.now());
  }

  DateTime _getWeekStart(DateTime date) {
    // Lunes de la semana
    final weekday = date.weekday; // 1=Lunes, 7=Domingo
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  void _previousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
    });
  }

  void _goToToday() {
    setState(() {
      _weekStart = _getWeekStart(DateTime.now());
    });
  }

  List<DateTime> _getWeekDays() {
    return List.generate(7, (i) => _weekStart.add(Duration(days: i)));
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  List<Task> _getTasksForDay(DateTime day, List<Task> allTasks) {
    return allTasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == day.year &&
          task.dueDate!.month == day.month &&
          task.dueDate!.day == day.day;
    }).toList();
  }

  void _openTask(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(task: task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TaskRepository>();
    final allTasks = repo.tasks;
    final weekDays = _getWeekDays();

    return Column(
      children: [
        // Navegación de semanas
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousWeek,
              ),
              GestureDetector(
                onTap: _goToToday,
                child: Text(
                  _formatWeekRange(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextWeek,
              ),
            ],
          ),
        ),

        // Grid de 7 columnas
        Expanded(
          child: Row(
            children: weekDays.map((day) {
              final tasksForDay = _getTasksForDay(day, allTasks);
              return Expanded(
                child: WeekDayColumn(
                  date: day,
                  tasks: tasksForDay,
                  isToday: _isToday(day),
                  onTaskTap: _openTask,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatWeekRange() {
    final end = _weekStart.add(const Duration(days: 6));
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${_weekStart.day} ${months[_weekStart.month - 1]} - ${end.day} ${months[end.month - 1]}';
  }
}
