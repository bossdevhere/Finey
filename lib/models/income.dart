import 'package:hive/hive.dart';
import 'transaction_item.dart';

class Income implements TransactionItem {
  @override
  final String id;
  @override
  final String title;
  @override
  final double amount;
  @override
  final String category;
  @override
  final DateTime date;
  final String notes;

  @override
  bool get isExpense => false;

  @override
  String get noteOrDescription => notes;

  Income({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.notes,
  });

  Income copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? notes,
  }) {
    return Income(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}

class IncomeAdapter extends TypeAdapter<Income> {
  @override
  final int typeId = 2;

  @override
  Income read(BinaryReader reader) {
    return Income(
      id: reader.readString(),
      title: reader.readString(),
      amount: reader.readDouble(),
      category: reader.readString(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      notes: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Income obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeDouble(obj.amount);
    writer.writeString(obj.category);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeString(obj.notes);
  }
}
