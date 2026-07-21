import 'package:hive/hive.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String priority; // High, Medium, Low
  final DateTime dueDate;
  final bool hasReminder;
  final bool isCompleted;
  final String category; // Personal, Work, Study, Health, Shopping

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.hasReminder,
    required this.isCompleted,
    required this.category,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    DateTime? dueDate,
    bool? hasReminder,
    bool? isCompleted,
    String? category,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      hasReminder: hasReminder ?? this.hasReminder,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
    );
  }
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 4;

  @override
  Task read(BinaryReader reader) {
    return Task(
      id: reader.readString(),
      title: reader.readString(),
      description: reader.readString(),
      priority: reader.readString(),
      dueDate: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      hasReminder: reader.readBool(),
      isCompleted: reader.readBool(),
      category: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.description);
    writer.writeString(obj.priority);
    writer.writeInt(obj.dueDate.millisecondsSinceEpoch);
    writer.writeBool(obj.hasReminder);
    writer.writeBool(obj.isCompleted);
    writer.writeString(obj.category);
  }
}
