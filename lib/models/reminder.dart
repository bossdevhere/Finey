import 'package:hive/hive.dart';

class Reminder {
  final String id;
  final String title;
  final String type; // One Time, Daily, Weekly, Monthly, Yearly
  final DateTime dateTime;
  final bool isCompleted;
  final bool repeat;
  final int snoozeCount;

  Reminder({
    required this.id,
    required this.title,
    required this.type,
    required this.dateTime,
    required this.isCompleted,
    required this.repeat,
    required this.snoozeCount,
  });

  Reminder copyWith({
    String? id,
    String? title,
    String? type,
    DateTime? dateTime,
    bool? isCompleted,
    bool? repeat,
    int? snoozeCount,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      isCompleted: isCompleted ?? this.isCompleted,
      repeat: repeat ?? this.repeat,
      snoozeCount: snoozeCount ?? this.snoozeCount,
    );
  }
}

class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = 5;

  @override
  Reminder read(BinaryReader reader) {
    return Reminder(
      id: reader.readString(),
      title: reader.readString(),
      type: reader.readString(),
      dateTime: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      isCompleted: reader.readBool(),
      repeat: reader.readBool(),
      snoozeCount: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.type);
    writer.writeInt(obj.dateTime.millisecondsSinceEpoch);
    writer.writeBool(obj.isCompleted);
    writer.writeBool(obj.repeat);
    writer.writeInt(obj.snoozeCount);
  }
}
