import 'package:flutter/material.dart';

class RecurrenceSelector extends StatelessWidget {
  final int selectedType;
  final ValueChanged<int> onChanged;

  const RecurrenceSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Recurrence Selector - To be implemented'),
    );
  }
}