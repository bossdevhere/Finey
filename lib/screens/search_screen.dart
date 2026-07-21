import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/search_provider.dart';
import '../providers/settings_provider.dart';
import 'note_detail_screen.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(globalSearchQueryProvider);
    final searchResult = ref.watch(globalSearchResultProvider);
    final currency = ref.read(settingsProvider).currency;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          style: TextStyle(color: colorScheme.onSurface, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Search expenses, notes, tasks...',
            hintStyle: TextStyle(color: colorScheme.outline),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            ref.read(globalSearchQueryProvider.notifier).state = value;
          },
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                ref.read(globalSearchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: query.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: colorScheme.outline.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  const Text('Type to search across all data...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : searchResult.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: colorScheme.outline.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text('No matching items found.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Notes matches
                    if (searchResult.matchingNotes.isNotEmpty) ...[
                      _buildHeader('Matching Notes', searchResult.matchingNotes.length),
                      ...searchResult.matchingNotes.map((note) => Card(
                            color: Color(note.color).withOpacity(0.15),
                            child: ListTile(
                              title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                note.content.isNotEmpty ? note.content : note.checklist.join(', '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => NoteDetailScreen(note: note)),
                                );
                              },
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Expenses matches
                    if (searchResult.matchingExpenses.isNotEmpty) ...[
                      _buildHeader('Matching Expenses', searchResult.matchingExpenses.length),
                      ...searchResult.matchingExpenses.map((exp) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.arrow_upward, color: Colors.red),
                              title: Text(exp.title),
                              subtitle: Text('${exp.category} • ${DateFormat('dd MMM').format(exp.date)}'),
                              trailing: Text(
                                '-$currency${exp.amount.toStringAsFixed(1)}',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Tasks matches
                    if (searchResult.matchingTasks.isNotEmpty) ...[
                      _buildHeader('Matching To-do Tasks', searchResult.matchingTasks.length),
                      ...searchResult.matchingTasks.map((task) => Card(
                            child: ListTile(
                              leading: Icon(
                                task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                                color: task.isCompleted ? Colors.green : Colors.grey,
                              ),
                              title: Text(task.title),
                              subtitle: Text('${task.category} • Priority: ${task.priority}'),
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Shopping Items matches
                    if (searchResult.matchingShoppingItems.isNotEmpty) ...[
                      _buildHeader('Matching Shopping Items', searchResult.matchingShoppingItems.length),
                      ...searchResult.matchingShoppingItems.map((s) => Card(
                            child: ListTile(
                              leading: Icon(
                                s.isPurchased ? Icons.check_box : Icons.check_box_outline_blank,
                                color: s.isPurchased ? Colors.green : Colors.grey,
                              ),
                              title: Text(s.name),
                              subtitle: Text('Qty: ${s.quantity} • Est. Cost: $currency${s.estimatedCost.toStringAsFixed(1)}'),
                            ),
                          )),
                    ],
                  ],
                ),
    );
  }

  Widget _buildHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
