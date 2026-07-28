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
              _showOnlyFavorites ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _showOnlyFavorites ? const Color(0xFFEF4444) : colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              setState(() {
                _showOnlyFavorites = !_showOnlyFavorites;
              });
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.12),
            ),
            child: IconButton(
              icon: Icon(Icons.add_rounded, color: colorScheme.primary),
              tooltip: 'New Note',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NoteDetailScreen()),
                );
              },
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search notes & checklists...',
                  prefixIcon: Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant),
                  fillColor: colorScheme.surface,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.outline, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.outline, width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                          Icon(Icons.edit_note_rounded, size: 56, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No notes created yet. Tap + to write one.'
                                : 'No matching notes found.',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return _buildNoteCard(note, colorScheme);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note, ColorScheme colorScheme) {
    final noteColor = note.color != 0xFFFFFFFF ? Color(note.color) : colorScheme.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NoteDetailScreen(note: note)),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: noteColor == colorScheme.surface ? colorScheme.surface : noteColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: note.isPinned ? colorScheme.primary : colorScheme.outline,
              width: note.isPinned ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Untitled Note' : note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (note.isPinned)
                    Icon(Icons.push_pin_rounded, size: 14, color: colorScheme.primary),
                  if (note.isFavorite)
                    const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFEF4444)),
                ],
              ),
              const SizedBox(height: 10),
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
                                    checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    size: 14,
                                    color: checked ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: checked
                                            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                                            : colorScheme.onSurface,
                                        decoration: checked ? TextDecoration.lineThrough : null,
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
                                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                              ),
                            ),
                        ],
                      )
                    : Text(
                        note.content,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
