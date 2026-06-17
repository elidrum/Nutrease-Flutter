import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../strings/it_strings.dart';
import '../theme/app_theme.dart';

/// Riga con date + time picker condivisa dai form di pasto e sintomo.
///
/// Limita la data a oggi (niente voci di diario nel futuro), fa il clamp del
/// valore iniziale e riporta le scelte via callback. [time] è la stringa DB
/// `HH:mm:ss`; [onTimeChanged] riporta il nuovo orario nello stesso formato.
class DateTimePickerRow extends StatelessWidget {
  final DateTime date;
  final String time;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String> onTimeChanged;

  const DateTimePickerRow({
    super.key,
    required this.date,
    required this.time,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd/MM/yyyy').format(date);
    // Mostro HH:mm; i secondi restano nello stato per il DB.
    final timeLabel = time.substring(0, 5);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(
              '${ItStrings.dateLabel}: $dateLabel',
              style: const TextStyle(fontSize: AppTokens.fontBody),
            ),
            onPressed: () => _pickDate(context),
          ),
        ),
        const SizedBox(width: AppTokens.spacingSm),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.schedule),
            label: Text(
              '${ItStrings.timeLabel}: $timeLabel',
              style: const TextStyle(fontSize: AppTokens.fontBody),
            ),
            onPressed: () => _pickTime(context),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    // Niente date future: limite a oggi e clamp della selezione iniziale.
    final today = DateTime.now();
    final initial = date.isAfter(today) ? today : date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: today,
    );
    if (picked != null) onDateChanged(picked);
  }

  Future<void> _pickTime(BuildContext context) async {
    final parts = time.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
    if (picked == null) return;
    String pad(int n) => n.toString().padLeft(2, '0');
    onTimeChanged('${pad(picked.hour)}:${pad(picked.minute)}:00');
  }
}
