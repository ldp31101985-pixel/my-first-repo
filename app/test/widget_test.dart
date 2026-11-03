import 'package:flutter_test/flutter_test.dart';
import 'package:quicknotes/models.dart';

void main() {
  test('Note переживает сериализацию в JSON', () {
    final n = Note(
      id: 'abc',
      title: 'Купить молоко',
      body: 'и хлеб',
      tags: ['дом'],
      reminderAt: DateTime(2026, 11, 5, 9, 30),
      repeat: Repeat.weekly,
      attachments: [
        Attachment(id: 'a1', name: 'чек.pdf', kind: AttachmentKind.pdf),
      ],
      pinned: true,
    );
    final back = Note.fromJson(n.toJson());
    expect(back.title, n.title);
    expect(back.tags, ['дом']);
    expect(back.reminderAt, n.reminderAt);
    expect(back.repeat, Repeat.weekly);
    expect(back.attachments.single.storedName, 'a1.pdf');
    expect(back.pinned, isTrue);
  });

  test('Пустая заметка определяется как пустая', () {
    expect(Note(id: 'x').isEmpty, isTrue);
    expect(Note(id: 'x', body: 'текст').isEmpty, isFalse);
  });
}
