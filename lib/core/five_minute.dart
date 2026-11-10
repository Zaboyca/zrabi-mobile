import 'package:flutter/material.dart';

DateTime alignToFiveMinutes(DateTime at) {
  final rounded = (at.minute / 5).round() * 5;
  return DateTime(at.year, at.month, at.day, at.hour).add(
    Duration(minutes: rounded),
  );
}

TimeOfDay alignTimeOfDay(TimeOfDay time) {
  final aligned = alignToFiveMinutes(
    DateTime(2020, 1, 1, time.hour, time.minute),
  );
  return TimeOfDay(hour: aligned.hour, minute: aligned.minute);
}

const fiveMinuteOptions = <int>[0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];

/// Час и минуты. В минутах только 00, 05, 10 … 55.
Future<TimeOfDay?> pickFiveMinuteTime(
  BuildContext context,
  TimeOfDay initial,
) {
  final aligned = alignTimeOfDay(initial);
  var hour = aligned.hour;
  var minute = aligned.minute;

  return showDialog<TimeOfDay>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Время'),
        content: StatefulBuilder(
          builder: (context, setLocal) {
            return Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    // ignore: deprecated_member_use
                    value: hour,
                    decoration: const InputDecoration(labelText: 'Час'),
                    items: [
                      for (var h = 0; h < 24; h++)
                        DropdownMenuItem(
                          value: h,
                          child: Text(h.toString().padLeft(2, '0')),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setLocal(() => hour = value);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(':'),
                ),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    // ignore: deprecated_member_use
                    value: minute,
                    decoration: const InputDecoration(labelText: 'Минуты'),
                    items: [
                      for (final m in fiveMinuteOptions)
                        DropdownMenuItem(
                          value: m,
                          child: Text(m.toString().padLeft(2, '0')),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setLocal(() => minute = value);
                    },
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              TimeOfDay(hour: hour, minute: minute),
            ),
            child: const Text('Ок'),
          ),
        ],
      );
    },
  );
}
