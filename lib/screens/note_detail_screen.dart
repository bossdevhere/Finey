import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final Note? note; // Null means creating a new note

  const NoteDetailScreen({super.key, this.note});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late int _selectedColor;
  late bool _isPinned;
  late bool _isFavorite;
  
  List<String> _checklist = [];
  List<bool> _checklistChecked = [];
  final TextEditingController _checklistTextController = TextEditingController();
  bool _isChecklistMode = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _selectedColor = widget.note?.color ?? 0xFF202124; // Default Dark Gray
    _isPinned = widget.note?.isPinned ?? false;
    _isFavorite = widget.note?.isFavorite ?? false;
    _checklist = widget.note?.checklist != null ? List<String>.from(widget.note!.checklist) : [];
    _checklistChecked = widget.note?.checklistChecked != null ? List<bool>.from(widget.note!.checklistChecked) : [];
    _isChecklistMode = _checklist.isNotEmpty;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _checklistTextController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty && _checklist.isEmpty) {
      // Nothing to save
      return;
    }

    final noteNotifier = ref.read(noteProvider.notifier);

    if (widget.note == null) {
      // Create new note
      final newNote = Note(
        id: const Uuid().v4(),
        title: title.isEmpty ? 'Untitled Note' : title,
        content: content,
        color: _selectedColor,
        isPinned: _isPinned,
        isFavorite: _isFavorite,
        checklist: _checklist,
        checklistChecked: _checklistChecked,
        lastModified: DateTime.now(),
      );
      noteNotifier.addNote(newNote);
    } else {
      // Update existing note
      final updatedNote = widget.note!.copyWith(
        title: title.isEmpty ? 'Untitled Note' : title,
        content: content,
        color: _selectedColor,
        isPinned: _isPinned,
        isFavorite: _isFavorite,
        checklist: _checklist,
        checklistChecked: _checklistChecked,
        lastModified: DateTime.now(),
      );
      noteNotifier.updateNote(updatedNote);
    }
  }



  void _addChecklistItem() {
    final text = _checklistTextController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _checklist.add(text);
      _checklistChecked.add(false);
      _checklistTextController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final noteBgColor = isDarkMode ? const Color(0xFF0E2012) : const Color(0xFFE8F5E9);
    final noteTextColor = isDarkMode ? Colors.white70 : Colors.black87;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _saveNote();
        }
      },
      child: Scaffold(
        backgroundColor: noteBgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: noteTextColor),
          actions: [
            IconButton(
              icon: Icon(
                _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: _isPinned ? theme.colorScheme.primary : noteTextColor,
              ),
              onPressed: () {
                setState(() {
                  _isPinned = !_isPinned;
                });
              },
            ),
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : noteTextColor,
              ),
              onPressed: () {
                setState(() {
                  _isFavorite = !_isFavorite;
                });
              },
            ),
            IconButton(
              icon: Icon(
                _isChecklistMode ? Icons.notes : Icons.checklist_outlined,
                color: noteTextColor,
              ),
              onPressed: () {
                setState(() {
                  _isChecklistMode = !_isChecklistMode;
                });
              },
            ),
            if (widget.note != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  ref.read(noteProvider.notifier).deleteNote(widget.note!.id);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: noteTextColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(color: noteTextColor.withOpacity(0.5)),
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(height: 12),
                    if (!_isChecklistMode) ...[
                      TextField(
                        controller: _contentController,
                        maxLines: null,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: noteTextColor.withOpacity(0.9),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write your thoughts here...',
                          hintStyle: TextStyle(color: noteTextColor.withOpacity(0.4)),
                          border: InputBorder.none,
                        ),
                      ),
                    ] else ...[
                      // Checklist list view builder
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _checklist.length,
                        itemBuilder: (context, index) {
                          return Row(
                            children: [
                              Checkbox(
                                activeColor: theme.colorScheme.primary,
                                value: _checklistChecked[index],
                                onChanged: (value) {
                                  setState(() {
                                    _checklistChecked[index] = value ?? false;
                                  });
                                },
                              ),
                              Expanded(
                                child: Text(
                                  _checklist[index],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: noteTextColor,
                                    decoration: _checklistChecked[index] ? TextDecoration.lineThrough : null,
                                    decorationColor: noteTextColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: noteTextColor.withOpacity(0.5)),
                                onPressed: () {
                                  setState(() {
                                    _checklist.removeAt(index);
                                    _checklistChecked.removeAt(index);
                                  });
                                },
                              )
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // Checklist item input row
                      Row(
                        children: [
                          Icon(Icons.add, color: noteTextColor.withOpacity(0.5)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _checklistTextController,
                              style: TextStyle(color: noteTextColor),
                              decoration: InputDecoration(
                                hintText: 'Add checklist item...',
                                hintStyle: TextStyle(color: noteTextColor.withOpacity(0.4)),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _addChecklistItem(),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.check, color: noteTextColor),
                            onPressed: _addChecklistItem,
                          )
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Footer metadata
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Last modified: ${widget.note == null ? "Just now" : DateFormat('dd MMM yyyy, hh:mm a').format(widget.note!.lastModified)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: noteTextColor.withOpacity(0.5),
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
