import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/database_helper.dart';
import 'data/task_repository.dart';
import 'providers/task_repository_provider.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseHelper = DatabaseHelper.instance;
  await databaseHelper.database;
  await databaseHelper.pruneOldCompletedTasks();

  final taskRepository = TaskRepository(databaseHelper);
  final notificationService = NotificationService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TaskRepositoryProvider(taskRepository),
        ),
        Provider.value(value: notificationService),
      ],
      child: const TaskTrackerApp(),
    ),
  );
}

class TaskTrackerApp extends StatelessWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskTracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}