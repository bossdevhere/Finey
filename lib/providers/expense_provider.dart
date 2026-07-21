import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/hive_database.dart';
import '../models/expense.dart';

class ExpenseNotifier extends StateNotifier<List<Expense>> {
  ExpenseNotifier() : super([]) {
    _loadExpenses();
  }

  void _loadExpenses() {
    final list = HiveDatabase.expenseBox.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date)); // Newest first
    state = list;
  }

  Future<void> addExpense(Expense expense) async {
    await HiveDatabase.expenseBox.put(expense.id, expense);
    _loadExpenses();
  }

  Future<void> updateExpense(Expense expense) async {
    await HiveDatabase.expenseBox.put(expense.id, expense);
    _loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await HiveDatabase.expenseBox.delete(id);
    _loadExpenses();
  }

  void clearAll() {
    state = [];
  }
}

final expenseProvider =
    StateNotifierProvider<ExpenseNotifier, List<Expense>>((ref) {
  return ExpenseNotifier();
});

// Category options
final expenseCategoriesProvider = Provider<List<String>>((ref) => [
      'Food',
      'Shopping',
      'Travel',
      'Bills',
      'Health',
      'Entertainment',
      'Education',
      'Fuel',
      'Other',
    ]);

// Payment methods
final paymentMethodsProvider = Provider<List<String>>((ref) => [
      'Cash',
      'UPI',
      'Card',
      'Net Banking',
    ]);
