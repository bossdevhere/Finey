import 'package:hive/hive.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String paymentMethod;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.paymentMethod,
  });

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    String? paymentMethod,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 1;

  @override
  Expense read(BinaryReader reader) {
    return Expense(
      id: reader.readString(),
      title: reader.readString(),
      amount: reader.readDouble(),
      category: reader.readString(),
      description: reader.readString(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      paymentMethod: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeDouble(obj.amount);
    writer.writeString(obj.category);
    writer.writeString(obj.description);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeString(obj.paymentMethod);
  }
}
