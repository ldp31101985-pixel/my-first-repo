import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../app_state.dart';
import 'notes_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.notesOn(_selected);
    final time = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Календарь')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Новая заметка сразу с напоминанием на выбранный день (09:00).
          final n = state.newNote()
            ..reminderAt = DateTime(
                _selected.year, _selected.month, _selected.day, 9);
          openEditor(context, n);
        },
        icon: const Icon(Icons.add_alarm),
        label: const Text('Напоминание'),
      ),
      body: Column(children: [
        TableCalendar<void>(
          locale: 'ru_RU',
          firstDay: DateTime.utc(2000),
          lastDay: DateTime.utc(2100),
          focusedDay: _focused,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Месяц'},
          selectedDayPredicate: (d) => isSameDay(d, _selected),
          eventLoader: (d) => state.hasEventOn(d) ? [null] : const [],
          onDaySelected: (sel, foc) => setState(() {
            _selected = sel;
            _focused = foc;
          }),
          onPageChanged: (foc) => _focused = foc,
        ),
        const Divider(height: 1),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('На этот день ничего нет'))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 88),
                  children: [
                    for (final n in items)
                      ListTile(
                        leading: Text(time.format(n.reminderAt!)),
                        title: Text(n.title.trim().isEmpty
                            ? (n.body.trim().isEmpty
                                ? 'Без названия'
                                : n.body.trim())
                            : n.title.trim()),
                        subtitle: n.body.trim().isEmpty || n.title.trim().isEmpty
                            ? null
                            : Text(n.body.trim(),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => openEditor(context, n.copy()),
                      ),
                  ],
                ),
        ),
      ]),
    );
  }
}
