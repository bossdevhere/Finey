abstract class TransactionItem {
  String get id;
  String get title;
  double get amount;
  String get category;
  DateTime get date;
  bool get isExpense;
  String get noteOrDescription;
}
