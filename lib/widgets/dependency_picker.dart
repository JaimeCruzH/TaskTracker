import 'package:flutter/material.dart';
import '../models/task.dart';

class DependencyPicker extends StatelessWidget {
  final String? selectedTaskId;
  final ValueChanged<String?> onChanged;
  final List<Task> availableTasks;
  final String? currentTaskId;

  const DependencyPicker({
    super.key,
    this.selectedTaskId,
    required this.onChanged,
    this.availableTasks = const [],
    this.currentTaskId,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTask = selectedTaskId != null
        ? availableTasks.where((t) => t.id == selectedTaskId).firstOrNull
        : null;

    return InkWell(
      onTap: () => _showTaskPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.link, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedTask != null
                    ? selectedTask.title
                    : 'Sin dependencia',
                style: TextStyle(
                  color: selectedTask != null ? Colors.black : Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selectedTaskId != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => onChanged(null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
          ],
        ),
      ),
    );
  }

  void _showTaskPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _TaskPickerSheet(
        availableTasks: availableTasks,
        currentTaskId: currentTaskId,
        selectedTaskId: selectedTaskId,
        onSelected: (taskId) {
          onChanged(taskId);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _TaskPickerSheet extends StatefulWidget {
  final List<Task> availableTasks;
  final String? currentTaskId;
  final String? selectedTaskId;
  final ValueChanged<String?> onSelected;

  const _TaskPickerSheet({
    required this.availableTasks,
    this.currentTaskId,
    this.selectedTaskId,
    required this.onSelected,
  });

  @override
  State<_TaskPickerSheet> createState() => _TaskPickerSheetState();
}

class _TaskPickerSheetState extends State<_TaskPickerSheet> {
  String _searchQuery = '';

  List<Task> get filteredTasks {
    return widget.availableTasks
        .where((t) => t.id != widget.currentTaskId)
        .where((t) =>
            _searchQuery.isEmpty ||
            t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seleccionar tarea padre',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar tarea...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No hay tareas disponibles'
                          : 'No se encontraron tareas',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      final isSelected = task.id == widget.selectedTaskId;
                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected ? Colors.green : Colors.grey,
                        ),
                        title: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: task.description != null
                            ? Text(
                                task.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        onTap: () => widget.onSelected(task.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}