import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';

class NoteEditor extends StatefulWidget {
  const NoteEditor({super.key, required this.note});
  final Note note;

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final Note _note = widget.note;
  late final _title = TextEditingController(text: _note.title);
  late final _body = TextEditingController(text: _note.body);
  final _tagInput = TextEditingController();
  final _removed = <Attachment>[];
  bool _deleted = false;

  bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _tagInput.dispose();
    super.dispose();
  }

  Future<void> _saveAndClose() async {
    if (_deleted) return;
    final state = context.read<AppState>();
    _note
      ..title = _title.text
      ..body = _body.text;
    _addTag(); // не теряем недописанный тег
    await state.save(_note);
    for (final a in _removed) {
      await state.removeAttachmentFile(a);
    }
  }

  void _addTag() {
    final raw = _tagInput.text.trim().replaceAll('#', '');
    if (raw.isEmpty) return;
    setState(() {
      if (!_note.tags.contains(raw)) _note.tags.add(raw);
      _tagInput.clear();
    });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _note.reminderAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    setState(() => _note.reminderAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _attachFromPath(String path, {String? name}) async {
    final a = await context
        .read<AppState>()
        .addAttachment(path, name: name);
    setState(() => _note.attachments.add(a));
  }

  Future<void> _takePhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera);
    if (x != null) await _attachFromPath(x.path, name: x.name);
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x != null) await _attachFromPath(x.path, name: x.name);
  }

  Future<void> _pickFiles() async {
    final files = await FilePicker.pickFiles();
    for (final f in files) {
      if (f.path != null) await _attachFromPath(f.path!, name: f.name);
    }
  }

  void _showAttachMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          if (_isMobile)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Сделать фото'),
              onTap: () {
                Navigator.pop(ctx);
                _takePhoto();
              },
            ),
          if (_isMobile)
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Фото из галереи'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage();
              },
            ),
          ListTile(
            leading: const Icon(Icons.attach_file),
            title: const Text('Файл / PDF / скриншот'),
            onTap: () {
              Navigator.pop(ctx);
              _pickFiles();
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
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
    );
    if (ok != true || !mounted) return;
    _deleted = true;
    await context.read<AppState>().delete(_note);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final fmt = DateFormat('d MMMM yyyy, HH:mm', 'ru_RU');

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _saveAndClose();
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              tooltip: _note.pinned ? 'Открепить' : 'Закрепить',
              icon: Icon(_note.pinned ? Icons.push_pin : Icons.push_pin_outlined),
              onPressed: () => setState(() => _note.pinned = !_note.pinned),
            ),
            IconButton(
              tooltip: 'Вложение',
              icon: const Icon(Icons.attach_file),
              onPressed: _showAttachMenu,
            ),
            IconButton(
              tooltip: 'Удалить',
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _title,
              style: Theme.of(context).textTheme.titleLarge,
              decoration: const InputDecoration(
                  hintText: 'Название', border: InputBorder.none),
              textCapitalization: TextCapitalization.sentences,
            ),
            TextField(
              controller: _body,
              minLines: 6,
              maxLines: null,
              autofocus: _note.isEmpty,
              decoration: const InputDecoration(
                  hintText: 'Текст заметки', border: InputBorder.none),
              textCapitalization: TextCapitalization.sentences,
            ),
            const Divider(),
            // Теги
            Wrap(spacing: 8, children: [
              for (final t in _note.tags)
                InputChip(
                  label: Text('#$t'),
                  onDeleted: () => setState(() => _note.tags.remove(t)),
                ),
            ]),
            TextField(
              controller: _tagInput,
              decoration: InputDecoration(
                hintText: 'Добавить тег',
                prefixIcon: const Icon(Icons.tag),
                suffixIcon: IconButton(
                    icon: const Icon(Icons.add), onPressed: _addTag),
              ),
              onSubmitted: (_) => _addTag(),
            ),
            const SizedBox(height: 16),
            // Напоминание
            Card(
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.alarm),
                  title: Text(_note.reminderAt == null
                      ? 'Добавить напоминание'
                      : fmt.format(_note.reminderAt!)),
                  trailing: _note.reminderAt == null
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            _note.reminderAt = null;
                            _note.repeat = Repeat.none;
                          }),
                        ),
                  onTap: _pickDateTime,
                ),
                if (_note.reminderAt != null)
                  ListTile(
                    leading: const Icon(Icons.repeat),
                    title: const Text('Повтор'),
                    trailing: DropdownButton<Repeat>(
                      value: _note.repeat,
                      underline: const SizedBox.shrink(),
                      onChanged: (v) =>
                          setState(() => _note.repeat = v ?? Repeat.none),
                      items: const [
                        DropdownMenuItem(
                            value: Repeat.none, child: Text('Не повторять')),
                        DropdownMenuItem(
                            value: Repeat.daily, child: Text('Каждый день')),
                        DropdownMenuItem(
                            value: Repeat.weekly, child: Text('Каждую неделю')),
                      ],
                    ),
                  ),
              ]),
            ),
            // Вложения
            if (_note.attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Вложения', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              for (final a in _note.attachments)
                _AttachmentTile(
                  attachment: a,
                  file: state.storage.attachmentFile(a),
                  onRemove: () => setState(() {
                    _note.attachments.remove(a);
                    _removed.add(a);
                  }),
                ),
            ],
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile(
      {required this.attachment, required this.file, required this.onRemove});
  final Attachment attachment;
  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isImage = attachment.kind == AttachmentKind.image;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        if (isImage)
          InkWell(
            onTap: () => OpenFilex.open(file.path),
            child: Image.file(file,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                    height: 80,
                    child: Center(child: Icon(Icons.broken_image_outlined)))),
          ),
        ListTile(
          leading: Icon(attachment.kind == AttachmentKind.pdf
              ? Icons.picture_as_pdf
              : isImage
                  ? Icons.image_outlined
                  : Icons.insert_drive_file_outlined),
          title: Text(attachment.name,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => OpenFilex.open(file.path),
          trailing: IconButton(
              tooltip: 'Убрать',
              icon: const Icon(Icons.close),
              onPressed: onRemove),
        ),
      ]),
    );
  }
}
