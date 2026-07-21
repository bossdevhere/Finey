import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/note_provider.dart';
import '../models/note.dart';
import 'note_detail_screen.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _searchQuery = '';
  bool _showOnlyFavorites = false;

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(noteProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filter notes based on search query and favorite filter
    final filteredNotes = notes.where((note) {
      final matchesSearch = note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.checklist.any((item) => item.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesFavorite = !_showOnlyFavorites || note.isFavorite;
      return matchesSearch && matchesFavorite;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Space & Notes'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
              color: _showOnlyFavorites ? Colors.red : null,
            ),
            onPressed: () {
              setState(() {
                _showOnlyFavorites = !_showOnlyFavorites;
              });
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.12),
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: theme.colorScheme.primary),
              tooltip: 'New Note',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NoteDetailScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search notes & checklists...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          Expanded(
            child: filteredNotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notes_rounded, size: 64, color: colorScheme.outline.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No notes yet. Tap + to create one.'
                              : 'No matching notes found.',
                          style: TextStyle(color: colorScheme.outline, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return _buildNoteCard(note);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final noteBgColor = isDarkMode ? const Color(0xFF0E2012) : const Color(0xFFE8F5E9);
    final noteTextColor = isDarkMode ? Colors.white70 : Colors.black87;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NoteDetailScreen(note: note)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: noteBgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
          border: Border.all(
            color: note.isPinned ? theme.colorScheme.primary : Colors.transparent,
            width: note.isPinned ? 2.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: noteTextColor,
                    ),
                  ),
                ),
                if (note.isPinned)
                  Icon(Icons.push_pin, size: 14, color: theme.colorScheme.primary),
                if (note.isFavorite)
                  const Icon(Icons.favorite, size: 14, color: Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: note.checklist.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...note.checklist.take(3).map((item) {
                          final idx = note.checklist.indexOf(item);
                          final checked = note.checklistChecked[idx];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                Icon(
                                  checked ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                                  size: 14,
                                  color: noteTextColor.withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: noteTextColor.withOpacity(checked ? 0.5 : 0.8),
                                      decoration: checked ? TextDecoration.lineThrough : null,
                                      decorationColor: noteTextColor.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (note.checklist.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '+ ${note.checklist.length - 3} more items',
                              style: TextStyle(fontSize: 11, color: noteTextColor.withOpacity(0.5)),
                            ),
                          ),
                      ],
                    )
                  : Text(
                      note.content,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: noteTextColor.withOpacity(0.75),
                        height: 1.4,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
