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
          style: TextStyle(color: colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Search expenses, notes...',
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            ref.read(globalSearchQueryProvider.notifier).state = value;
          },
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close_rounded, color: colorScheme.onSurfaceVariant),
              onPressed: () {
                ref.read(globalSearchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: SafeArea(
        child: query.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_rounded, size: 56, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'Type to search across expenses and notes...',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            : searchResult.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 56, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'No matches found for "$query"',
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Expenses matches
                      if (searchResult.matchingExpenses.isNotEmpty) ...[
                        _buildHeader('EXPENSES', searchResult.matchingExpenses.length, colorScheme),
                        const SizedBox(height: 6),
                        ...searchResult.matchingExpenses.map((exp) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: colorScheme.outline, width: 1),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0x1FEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFFEF4444), size: 18),
                                ),
                                title: Text(exp.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: colorScheme.onSurface)),
                                subtitle: Text('${exp.category} • ${DateFormat('dd MMM').format(exp.date)}', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                trailing: Text(
                                  '-$currency${exp.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                              ),
                            )),
                        const SizedBox(height: 16),
                      ],

                      // Notes matches
                      if (searchResult.matchingNotes.isNotEmpty) ...[
                        _buildHeader('NOTES & LISTS', searchResult.matchingNotes.length, colorScheme),
                        const SizedBox(height: 6),
                        ...searchResult.matchingNotes.map((note) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: colorScheme.outline, width: 1),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.edit_note_rounded, color: colorScheme.primary, size: 18),
                                ),
                                title: Text(note.title.isEmpty ? 'Untitled Note' : note.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: colorScheme.onSurface)),
                                subtitle: Text(
                                  note.content.isNotEmpty ? note.content : note.checklist.join(', '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => NoteDetailScreen(note: note)),
                                  );
                                },
                              ),
                            )),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader(String title, int count, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: colorScheme.onSurfaceVariant, letterSpacing: 1.1),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Text(
              '$count',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
          )
        ],
      ),
    );
  }
}
