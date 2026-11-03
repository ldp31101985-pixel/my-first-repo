import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'notifications.dart';
import 'storage.dart';

class AppState extends ChangeNotifier {
  AppState(this.storage, this.notifications);

  final Storage storage;
  final NotificationService notifications;
  final _uuid = const Uuid();

  List<Note> _notes = [];
  String query = '';
  String? tagFilter;

  Future<void> load() async {
    _notes = await storage.loadNotes();
    for (final n in _notes) {
      await notifications.schedule(n);
    }
    notifyListeners();
  }

  Note newNote() => Note(id: _uuid.v4());

  Note? byId(String id) {
    for (final n in _notes) {
      if (n.id == id) return n;
    }
    return null;
  }

  /// Заметки с учётом поиска и фильтра по тегу: закреплённые сверху,
  /// затем по дате изменения.
  List<Note> get visible {
    final q = query.trim().toLowerCase();
    final list = _notes.where((n) {
      if (tagFilter != null && !n.tags.contains(tagFilter)) return false;
      if (q.isEmpty) return true;
      return n.title.toLowerCase().contains(q) ||
          n.body.toLowerCase().contains(q) ||
          n.tags.any((t) => t.toLowerCase().contains(q));
    }).toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return list;
  }

  List<String> get allTags {
    final s = <String>{for (final n in _notes) ...n.tags};
    return s.toList()..sort();
  }

  /// Заметки, у которых напоминание попадает на указанный день.
  List<Note> notesOn(DateTime day) => _notes.where((n) {
        final r = n.reminderAt;
        return r != null &&
            r.year == day.year &&
            r.month == day.month &&
            r.day == day.day;
      }).toList()
        ..sort((a, b) => a.reminderAt!.compareTo(b.reminderAt!));

  bool hasEventOn(DateTime day) => notesOn(day).isNotEmpty;

  void setQuery(String v) {
    query = v;
    notifyListeners();
  }

  void setTagFilter(String? tag) {
    tagFilter = tag;
    notifyListeners();
  }

  Future<void> save(Note note) async {
    note.updatedAt = DateTime.now();
    final i = _notes.indexWhere((n) => n.id == note.id);
    if (note.isEmpty && note.reminderAt == null) {
      if (i != -1) await delete(note);
      return;
    }
    if (i == -1) {
      _notes.add(note);
    } else {
      _notes[i] = note;
    }
    await storage.saveNotes(_notes);
    await notifications.schedule(note);
    if (tagFilter != null && !allTags.contains(tagFilter)) tagFilter = null;
    notifyListeners();
  }

  Future<void> delete(Note note) async {
    _notes.removeWhere((n) => n.id == note.id);
    await notifications.cancel(note);
    for (final a in note.attachments) {
      await storage.deleteAttachmentFile(a);
    }
    await storage.saveNotes(_notes);
    if (tagFilter != null && !allTags.contains(tagFilter)) tagFilter = null;
    notifyListeners();
  }

  /// Копирует файл в хранилище приложения и возвращает вложение.
  Future<Attachment> addAttachment(String sourcePath, {String? name}) async {
    final fileName = name ?? p.basename(sourcePath);
    final ext = p.extension(fileName).toLowerCase();
    final kind = const {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.bmp'}
            .contains(ext)
        ? AttachmentKind.image
        : ext == '.pdf'
            ? AttachmentKind.pdf
            : AttachmentKind.file;
    final att = Attachment(id: _uuid.v4(), name: fileName, kind: kind);
    await File(sourcePath).copy(storage.attachmentFile(att).path);
    return att;
  }

  Future<void> removeAttachmentFile(Attachment a) =>
      storage.deleteAttachmentFile(a);
}
