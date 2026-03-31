import 'package:flutter/material.dart';

class DependencyPicker extends StatelessWidget {
  final String? selectedTaskId;
  final ValueChanged<String?> onChanged;

  const DependencyPicker({
    super.key,
    this.selectedTaskId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Dependency Picker - To be implemented'),
    );
  }
}