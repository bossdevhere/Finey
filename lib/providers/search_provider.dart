import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'expense_provider.dart';
import 'note_provider.dart';
import 'task_provider.dart';
import 'shopping_provider.dart';
import '../models/expense.dart';
import '../models/note.dart';
import '../models/task.dart';
import '../models/shopping_item.dart';

final globalSearchQueryProvider = StateProvider<String>((ref) => '');

class GlobalSearchResult {
  final List<Expense> matchingExpenses;
  final List<Note> matchingNotes;
  final List<Task> matchingTasks;
  final List<ShoppingItem> matchingShoppingItems;

  GlobalSearchResult({
    required this.matchingExpenses,
    required this.matchingNotes,
    required this.matchingTasks,
    required this.matchingShoppingItems,
  });

  bool get isEmpty =>
      matchingExpenses.isEmpty &&
      matchingNotes.isEmpty &&
      matchingTasks.isEmpty &&
      matchingShoppingItems.isEmpty;
}

final globalSearchResultProvider = Provider<GlobalSearchResult>((ref) {
  final query = ref.watch(globalSearchQueryProvider).toLowerCase().trim();
  if (query.isEmpty) {
    return GlobalSearchResult(
      matchingExpenses: [],
      matchingNotes: [],
      matchingTasks: [],
      matchingShoppingItems: [],
    );
  }

  final expenses = ref.watch(expenseProvider);
  final notes = ref.watch(noteProvider);
  final tasks = ref.watch(taskProvider);
  final shoppingItems = ref.watch(shoppingProvider);

  final matchingExpenses = expenses
      .where((e) =>
          e.title.toLowerCase().contains(query) ||
          e.category.toLowerCase().contains(query) ||
          e.description.toLowerCase().contains(query))
      .toList();

  final matchingNotes = notes
      .where((n) =>
          n.title.toLowerCase().contains(query) ||
          n.content.toLowerCase().contains(query) ||
          n.checklist.any((item) => item.toLowerCase().contains(query)))
      .toList();

  final matchingTasks = tasks
      .where((t) =>
          t.title.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query) ||
          t.category.toLowerCase().contains(query))
      .toList();

  final matchingShoppingItems = shoppingItems
      .where((s) => s.name.toLowerCase().contains(query))
      .toList();

  return GlobalSearchResult(
    matchingExpenses: matchingExpenses,
    matchingNotes: matchingNotes,
    matchingTasks: matchingTasks,
    matchingShoppingItems: matchingShoppingItems,
  );
});
