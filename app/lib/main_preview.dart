// Демо-версия для просмотра в браузере: данные в памяти, без файлов.
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'main.dart';
import 'models.dart';
import 'notifications.dart';
import 'storage.dart';

class MemoryStorage extends Storage {
  MemoryStorage(this.seed);
  final List<Note> seed;

  @override
  Future<List<Note>> loadNotes() async => seed;
  @override
  Future<void> saveNotes(List<Note> notes) async {}
  @override
  Future<void> deleteAttachmentFile(Attachment a) async {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU');
  final now = DateTime.now();
  DateTime at(int d, int h, int m) =>
      DateTime(now.year, now.month, now.day + d, h, m);
  final notes = [
    Note(id: '1', title: 'Купить продукты', body: 'Молоко, хлеб, яйца, сыр', tags: ['дом'], reminderAt: at(0, 18, 30), pinned: true),
    Note(id: '2', title: 'Созвон с командой', body: 'Обсудить план релиза и сроки', tags: ['работа'], reminderAt: at(1, 11, 0), repeat: Repeat.weekly),
    Note(id: '3', title: 'Договор аренды', body: 'Проверить пункты 4 и 7 перед подписанием', tags: ['документы', 'важное'],
        attachments: [Attachment(id: 'a', name: 'dogovor.pdf', kind: AttachmentKind.pdf), Attachment(id: 'b', name: 'скриншот.png', kind: AttachmentKind.file)]),
    Note(id: '4', title: 'Принять витамины', tags: ['здоровье'], reminderAt: at(0, 9, 0), repeat: Repeat.daily),
    Note(id: '5', title: 'Идея для проекта', body: 'Сделать приложение для быстрых заметок с синхронизацией', tags: ['идеи'], reminderAt: at(3, 15, 0)),
  ];
  final state = AppState(MemoryStorage(notes), NotificationService());
  await state.load();
  runApp(ChangeNotifierProvider.value(value: state, child: const QuickNotesApp()));
}
