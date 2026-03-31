import 'package:flutter/material.dart';
import '../data/task_repository.dart';
import '../models/task.dart';

class TaskRepositoryProvider extends ChangeNotifier {
  final TaskRepository _repository;

  TaskRepositoryProvider(this._repository);

  TaskRepository get repository => _repository;

  Future<void> loadTasks() async {
    await _repository.loadTasks();
    notifyListeners();
  }

  Map<String, List<Task>> get groupedTasks => _repository.groupedTasks;
}