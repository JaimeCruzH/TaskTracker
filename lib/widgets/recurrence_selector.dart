import 'package:flutter/material.dart';
import '../models/task.dart';

class RecurrenceSelector extends StatelessWidget {
  final RecurrenceType selectedType;
  final ValueChanged<RecurrenceType> onChanged;

  const RecurrenceSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recurrencia',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RecurrenceType.values.map((type) {
            final isSelected = type == selectedType;
            return ChoiceChip(
              label: Text(_getLabel(type)),
              selected: isSelected,
              onSelected: (_) => onChanged(type),
              avatar: Icon(
                _getIcon(type),
                size: 18,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return 'Ninguna';
      case RecurrenceType.daily:
        return 'Diaria';
      case RecurrenceType.weekly:
        return 'Semanal';
      case RecurrenceType.monthly:
        return 'Mensual';
      case RecurrenceType.yearly:
        return 'Anual';
    }
  }

  IconData _getIcon(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return Icons.not_interested;
      case RecurrenceType.daily:
        return Icons.today;
      case RecurrenceType.weekly:
        return Icons.date_range;
      case RecurrenceType.monthly:
        return Icons.calendar_month;
      case RecurrenceType.yearly:
        return Icons.event;
    }
  }
}