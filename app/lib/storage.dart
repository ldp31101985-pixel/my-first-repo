import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'models.dart';

/// Локальное хранилище: notes.json + папка attachments/.
/// Формат файлов выбран так, чтобы позже его можно было целиком
/// синхронизировать через Google Drive.
class Storage {
  Storage([this.root]);

  final Directory? root;

  File get _notesFile => File(p.join(root!.path, 'notes.json'));
  Directory get attachmentsDir => Directory(p.join(root!.path, 'attachments'));

  static Future<Storage> open() async {
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(docs.path, 'QuickNotes'));
    await root.create(recursive: true);
    final s = Storage(root);
    await s.attachmentsDir.create(recursive: true);
    return s;
  }

  Future<List<Note>> loadNotes() async {
    if (!await _notesFile.exists()) return [];
    try {
      final data = jsonDecode(await _notesFile.readAsString()) as List;
      return data
          .map((e) => Note.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      // Повреждённый файл не должен ронять приложение: сохраняем копию.
      await _notesFile.copy('${_notesFile.path}.broken');
      return [];
    }
  }

  Future<void> saveNotes(List<Note> notes) async {
    final tmp = File('${_notesFile.path}.tmp');
    await tmp.writeAsString(jsonEncode(notes.map((n) => n.toJson()).toList()));
    await tmp.rename(_notesFile.path);
  }

  File attachmentFile(Attachment a) =>
      File(p.join(attachmentsDir.path, a.storedName));

  Future<void> deleteAttachmentFile(Attachment a) async {
    final f = attachmentFile(a);
    if (await f.exists()) await f.delete();
  }
}
