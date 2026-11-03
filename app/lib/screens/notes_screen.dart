import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import 'note_editor.dart';

Future<void> openEditor(BuildContext context, Note note) =>
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditor(note: note)),
    );

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final notes = state.visible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickNotes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              hintText: 'Поиск по заметкам и тегам',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: state.setQuery,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openEditor(context, state.newNote()),
        icon: const Icon(Icons.add),
        label: const Text('Заметка'),
      ),
      body: Column(children: [
        if (state.allTags.isNotEmpty)
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final t in state.allTags)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('#$t'),
                      selected: state.tagFilter == t,
                      onSelected: (v) => state.setTagFilter(v ? t : null),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: notes.isEmpty
              ? Center(
                  child: Text(
                    state.query.isEmpty && state.tagFilter == null
                        ? 'Пока нет заметок.\nНажмите «Заметка», чтобы начать.'
                        : 'Ничего не найдено',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                  itemCount: notes.length,
                  itemBuilder: (_, i) => _NoteTile(note: notes[i]),
                ),
        ),
      ]),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note});
  final Note note;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final fmt = DateFormat('d MMM, HH:mm', 'ru_RU');
    final title = note.title.trim().isEmpty ? 'Без названия' : note.title.trim();

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Theme.of(context).colorScheme.errorContainer,
        child: const Icon(Icons.delete_outline),
      ),
      confirmDismiss: (_) async =>
          await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Удалить заметку?'),
              content: const Text('Вместе с вложениями. Это нельзя отменить.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Отмена')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Удалить')),
              ],
            ),
          ) ??
          false,
      onDismissed: (_) => state.delete(note),
      child: Card(
        child: ListTile(
          onTap: () => openEditor(context, note.copy()),
          leading: note.pinned ? const Icon(Icons.push_pin) : null,
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.body.trim().isNotEmpty)
                Text(note.body.trim(),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Wrap(spacing: 8, runSpacing: 2, children: [
                if (note.reminderAt != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.alarm, size: 14),
                    const SizedBox(width: 2),
                    Text(fmt.format(note.reminderAt!)),
                  ]),
                if (note.attachments.isNotEmpty)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.attach_file, size: 14),
                    Text('${note.attachments.length}'),
                  ]),
                for (final t in note.tags) Text('#$t'),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
