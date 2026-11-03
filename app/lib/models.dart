enum Repeat { none, daily, weekly }

enum AttachmentKind { image, pdf, file }

class Attachment {
  Attachment({required this.id, required this.name, required this.kind});

  final String id;

  /// Исходное имя файла (показывается пользователю).
  final String name;
  final AttachmentKind kind;

  /// Имя файла в папке вложений: `<id><расширение>`.
  String get storedName {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? id : '$id${name.substring(dot)}';
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'kind': kind.name};

  factory Attachment.fromJson(Map<String, dynamic> j) => Attachment(
        id: j['id'] as String,
        name: j['name'] as String,
        kind: AttachmentKind.values.byName(j['kind'] as String),
      );
}

class Note {
  Note({
    required this.id,
    this.title = '',
    this.body = '',
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.reminderAt,
    this.repeat = Repeat.none,
    List<Attachment>? attachments,
    this.pinned = false,
  })  : tags = tags ?? [],
        attachments = attachments ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String title;
  String body;
  List<String> tags;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? reminderAt;
  Repeat repeat;
  List<Attachment> attachments;
  bool pinned;

  bool get isEmpty =>
      title.trim().isEmpty && body.trim().isEmpty && attachments.isEmpty;

  /// Числовой id для системного уведомления (стабильный для заметки).
  int get notificationId => id.hashCode & 0x7fffffff;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'reminderAt': reminderAt?.toIso8601String(),
        'repeat': repeat.name,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'pinned': pinned,
      };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        tags: (j['tags'] as List? ?? []).cast<String>(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        reminderAt: j['reminderAt'] == null
            ? null
            : DateTime.parse(j['reminderAt'] as String),
        repeat: Repeat.values.byName(j['repeat'] as String? ?? 'none'),
        attachments: (j['attachments'] as List? ?? [])
            .map((a) => Attachment.fromJson(Map<String, dynamic>.from(a)))
            .toList(),
        pinned: j['pinned'] as bool? ?? false,
      );

  Note copy() => Note.fromJson(toJson());
}
