import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/hive_database.dart';
import '../models/note.dart';

class NoteNotifier extends StateNotifier<List<Note>> {
  NoteNotifier() : super([]) {
    _loadNotes();
  }

  void _loadNotes() {
    final list = HiveDatabase.noteBox.values.toList();
    // Sort notes: pinned first, then last modified date (newest first)
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.lastModified.compareTo(a.lastModified);
    });
    state = list;
  }

  Future<void> addNote(Note note) async {
    await HiveDatabase.noteBox.put(note.id, note);
    _loadNotes();
  }

  Future<void> updateNote(Note note) async {
    final updatedNote = note.copyWith(lastModified: DateTime.now());
    await HiveDatabase.noteBox.put(note.id, updatedNote);
    _loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await HiveDatabase.noteBox.delete(id);
    _loadNotes();
  }

  Future<void> togglePin(String id) async {
    final note = HiveDatabase.noteBox.get(id);
    if (note != null) {
      final updated = note.copyWith(isPinned: !note.isPinned);
      await updateNote(updated);
    }
  }

  Future<void> toggleFavorite(String id) async {
    final note = HiveDatabase.noteBox.get(id);
    if (note != null) {
      final updated = note.copyWith(isFavorite: !note.isFavorite);
      await updateNote(updated);
    }
  }

  void clearAll() {
    state = [];
  }
}

final noteProvider = StateNotifierProvider<NoteNotifier, List<Note>>((ref) {
  return NoteNotifier();
});

// Color options for notes
final noteColorsProvider = Provider<List<int>>((ref) => [
      0xFF202124, // Dark Grey (default background)
      0xFFF28B82, // Light Red
      0xFFFBBC04, // Light Orange/Yellow
      0xFFFFF475, // Light Yellow
      0xFFCCFF90, // Light Green
      0xFFA7FFEB, // Light Teal
      0xFFCBF0F8, // Light Blue
      0xFFAECBFA, // Darker Blue
      0xFFD7AEFB, // Light Purple
      0xFFFDCFE8, // Light Pink
      0xFFE6C9A8, // Light Brown
      0xFFE8EAED, // Soft light gray
    ]);
