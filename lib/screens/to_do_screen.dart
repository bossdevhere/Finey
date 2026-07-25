import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class ToDoScreen extends ConsumerStatefulWidget {
  const ToDoScreen({super.key});

  @override
  ConsumerState<ToDoScreen> createState() => _ToDoScreenState();
}

class _ToDoScreenState extends ConsumerState<ToDoScreen> {
  String _selectedCategoryFilter = 'All';
  bool _showCompleted = false;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedPriority = 'Medium';
  String _selectedCategory = 'Personal';
  DateTime _dueDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showAddTaskSheet({Task? editingTask}) {
    if (editingTask != null) {
      _titleController.text = editingTask.title;
      _descController.text = editingTask.description;
      _selectedPriority = editingTask.priority;
      _selectedCategory = editingTask.category;
      _dueDate = editingTask.dueDate;
    } else {
      _titleController.clear();
      _descController.clear();
      _selectedPriority = 'Medium';
      _selectedCategory = 'Personal';
      _dueDate = DateTime.now();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final bottomPadding = MediaQuery.of(context).padding.bottom;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: bottomInset > 0 ? bottomInset + 16 : bottomPadding + 24,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: colorScheme.outline, width: 1),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      editingTask == null ? 'Create New Task' : 'Edit Task',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        hintText: 'e.g. Pay Internet Bill, Gym session',
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _descController,
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPriority,
                            isExpanded: true,
                            style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(labelText: 'Priority'),
                            items: ['Low', 'Medium', 'High'].map((p) {
                              return DropdownMenuItem(value: p, child: Text(p));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setSheetState(() => _selectedPriority = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: ['Personal', 'Work', 'Finance', 'Health', 'Shopping'].map((c) {
                              return DropdownMenuItem(value: c, child: Text(c));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setSheetState(() => _selectedCategory = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Due Date Picker Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: colorScheme.outline, width: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      icon: Icon(Icons.event_rounded, size: 18, color: colorScheme.onSurface),
                      label: Text(
                        'Due: ${DateFormat('dd MMM yyyy').format(_dueDate)}',
                        style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setSheetState(() => _dueDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 0,
                        ),
                        onPressed: () {
                          final title = _titleController.text.trim();
                          if (title.isEmpty) return;

                          final taskNotifier = ref.read(taskProvider.notifier);
                          if (editingTask == null) {
                            final task = Task(
                              id: const Uuid().v4(),
                              title: title,
                              description: _descController.text.trim(),
                              priority: _selectedPriority,
                              dueDate: _dueDate,
                              hasReminder: false,
                              isCompleted: false,
                              category: _selectedCategory,
                            );
                            taskNotifier.addTask(task);
                          } else {
                            final task = editingTask.copyWith(
                              title: title,
                              description: _descController.text.trim(),
                              priority: _selectedPriority,
                              dueDate: _dueDate,
                              category: _selectedCategory,
                            );
                            taskNotifier.updateTask(task);
                          }
                          Navigator.pop(context);
                        },
                        child: Text(
                          editingTask == null ? 'Create Task' : 'Save Changes',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filter list
    final filteredTasks = tasks.where((task) {
      final matchesCategory = _selectedCategoryFilter == 'All' || task.category == _selectedCategoryFilter;
      final matchesCompletion = _showCompleted || !task.isCompleted;
      return matchesCategory && matchesCompletion;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('To-do Tasks'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showCompleted ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: () => setState(() => _showCompleted = !_showCompleted),
            tooltip: 'Toggle Completed',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(),
        elevation: 3,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter categories horizontal scroll
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: ['All', 'Personal', 'Work', 'Finance', 'Health', 'Shopping'].map((cat) {
                  final isSelected = _selectedCategoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryFilter = cat;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: filteredTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.task_alt_rounded, size: 56, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text(
                            'No tasks found.',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return _buildTaskCard(task, colorScheme);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task, ColorScheme scheme) {
    Color priorityColor;
    if (task.priority == 'High') {
      priorityColor = const Color(0xFFEF4444);
    } else if (task.priority == 'Medium') {
      priorityColor = const Color(0xFFF59E0B);
    } else {
      priorityColor = const Color(0xFF10B981);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: IconButton(
          icon: Icon(
            task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: task.isCompleted ? const Color(0xFF10B981) : scheme.onSurfaceVariant,
            size: 22,
          ),
          onPressed: () {
            ref.read(taskProvider.notifier).toggleCompleted(task.id);
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? scheme.onSurfaceVariant : scheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.priority,
                    style: TextStyle(color: priorityColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Due: ${DateFormat('dd MMM').format(task.dueDate)}',
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Text(
                  '#${task.category}',
                  style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 18, color: scheme.onSurfaceVariant),
              onPressed: () => _showAddTaskSheet(editingTask: task),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
              onPressed: () {
                ref.read(taskProvider.notifier).deleteTask(task.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
