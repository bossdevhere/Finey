import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'expense_provider.dart';
import 'note_provider.dart';
import '../models/expense.dart';
import '../models/note.dart';

final globalSearchQueryProvider = StateProvider<String>((ref) => '');

class GlobalSearchResult {
  final List<Expense> matchingExpenses;
  final List<Note> matchingNotes;

  GlobalSearchResult({
    required this.matchingExpenses,
    required this.matchingNotes,
  });

  bool get isEmpty => matchingExpenses.isEmpty && matchingNotes.isEmpty;
}

final globalSearchResultProvider = Provider<GlobalSearchResult>((ref) {
  final query = ref.watch(globalSearchQueryProvider).toLowerCase().trim();
  if (query.isEmpty) {
    return GlobalSearchResult(
      matchingExpenses: [],
      matchingNotes: [],
    );
  }

  final expenses = ref.watch(expenseProvider);
  final notes = ref.watch(noteProvider);

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

  return GlobalSearchResult(
    matchingExpenses: matchingExpenses,
    matchingNotes: matchingNotes,
  );
});
