import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/hive_database.dart';
import '../models/income.dart';

class IncomeNotifier extends StateNotifier<List<Income>> {
  IncomeNotifier() : super([]) {
    _loadIncomes();
  }

  void _loadIncomes() {
    final list = HiveDatabase.incomeBox.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date)); // Newest first
    state = list;
  }

  Future<void> addIncome(Income income) async {
    await HiveDatabase.incomeBox.put(income.id, income);
    _loadIncomes();
  }

  Future<void> updateIncome(Income income) async {
    await HiveDatabase.incomeBox.put(income.id, income);
    _loadIncomes();
  }

  Future<void> deleteIncome(String id) async {
    await HiveDatabase.incomeBox.delete(id);
    _loadIncomes();
  }

  void clearAll() {
    state = [];
  }
}

final incomeProvider =
    StateNotifierProvider<IncomeNotifier, List<Income>>((ref) {
  return IncomeNotifier();
});

// Income Categories
final incomeCategoriesProvider = Provider<List<String>>((ref) => [
      'Salary',
      'Freelancing',
      'Gift',
      'Business',
      'Other',
    ]);
