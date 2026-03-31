import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/database_helper.dart';
import 'data/task_repository.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseHelper = DatabaseHelper();
  await databaseHelper.database;

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

class TaskRepositoryProvider extends ChangeNotifier {
  final TaskRepository _repository;

  TaskRepositoryProvider(this._repository);

  TaskRepository get repository => _repository;
}