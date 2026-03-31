import 'package:flutter/material.dart';

class DurationSelector extends StatelessWidget {
  final int? initialMinutes;
  final ValueChanged<int?>? onChanged;

  const DurationSelector({
    super.key,
    this.initialMinutes,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: initialMinutes != null && initialMinutes! > 1
              ? () => onChanged?.call((initialMinutes! - 15).clamp(1, 1440))
              : null,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        GestureDetector(
          onTap: () => _showTimePicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatDuration(initialMinutes),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: initialMinutes != null && initialMinutes! < 1440
              ? () => onChanged?.call((initialMinutes! + 15).clamp(1, 1440))
              : initialMinutes == null
                  ? () => onChanged?.call(15)
                  : null,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return 'Sin duracion';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${mins}m';
    }
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final currentMinutes = initialMinutes ?? 30;
    final initialHour = currentMinutes ~/ 60;
    final initialMinute = currentMinutes % 60;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      helpText: 'Seleccionar duracion',
    );

    if (picked != null) {
      final totalMinutes = picked.hour * 60 + picked.minute;
      if (totalMinutes > 0 && totalMinutes <= 1440) {
        onChanged?.call(totalMinutes);
      }
    }
  }
}