import 'package:hive/hive.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final int color; // ARGB value
  final bool isPinned;
  final bool isFavorite;
  final List<String> checklist;
  final List<bool> checklistChecked;
  final DateTime lastModified;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.color,
    required this.isPinned,
    required this.isFavorite,
    required this.checklist,
    required this.checklistChecked,
    required this.lastModified,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    int? color,
    bool? isPinned,
    bool? isFavorite,
    List<String>? checklist,
    List<bool>? checklistChecked,
    DateTime? lastModified,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      checklist: checklist ?? this.checklist,
      checklistChecked: checklistChecked ?? this.checklistChecked,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 6;

  @override
  Note read(BinaryReader reader) {
    return Note(
      id: reader.readString(),
      title: reader.readString(),
      content: reader.readString(),
      color: reader.readInt(),
      isPinned: reader.readBool(),
      isFavorite: reader.readBool(),
      checklist: reader.readStringList(),
      checklistChecked: List<bool>.from(reader.readList()),
      lastModified: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.content);
    writer.writeInt(obj.color);
    writer.writeBool(obj.isPinned);
    writer.writeBool(obj.isFavorite);
    writer.writeStringList(obj.checklist);
    writer.writeList(obj.checklistChecked);
    writer.writeInt(obj.lastModified.millisecondsSinceEpoch);
  }
}
