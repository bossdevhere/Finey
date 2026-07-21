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
  bool _hasReminder = false;

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
      _hasReminder = editingTask.hasReminder;
    } else {
      _titleController.clear();
      _descController.clear();
      _selectedPriority = 'Medium';
      _selectedCategory = 'Personal';
      _dueDate = DateTime.now();
      _hasReminder = false;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    editingTask == null ? 'Create New Task' : 'Edit Task',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Category drop down
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: ref.read(taskCategoriesProvider).map((cat) {
                            return DropdownMenuItem(value: cat, child: Text(cat));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => _selectedCategory = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Priority dropdown
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedPriority,
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: ['High', 'Medium', 'Low'].map((prio) {
                            return DropdownMenuItem(value: prio, child: Text(prio));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => _selectedPriority = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Due Date picker
                  ListTile(
                    title: const Text('Due Date'),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(_dueDate)),
                    leading: const Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (selected != null) {
                        setSheetState(() => _dueDate = selected);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Enable Reminder'),
                    subtitle: const Text('Notify me on due date'),
                    secondary: const Icon(Icons.notifications_active_outlined),
                    value: _hasReminder,
                    onChanged: (val) {
                      setSheetState(() => _hasReminder = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                            hasReminder: _hasReminder,
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
                            hasReminder: _hasReminder,
                            category: _selectedCategory,
                          );
                          taskNotifier.updateTask(task);
                        }
                        Navigator.pop(context);
                      },
                      child: Text(editingTask == null ? 'Create Task' : 'Save Changes'),
                    ),
                  ),
                ],
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
            icon: Icon(_showCompleted ? Icons.visibility : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _showCompleted = !_showCompleted),
            tooltip: 'Show Completed',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(),
        child: const Icon(Icons.add_task),
      ),
      body: Column(
        children: [
          // Horizontal Category Filter List
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: ['All', ...ref.read(taskCategoriesProvider)].map((cat) {
                final isSelected = _selectedCategoryFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _selectedCategoryFilter = cat;
                      });
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        Icon(Icons.assignment_turned_in_outlined, size: 64, color: colorScheme.outline.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No tasks found.',
                          style: TextStyle(color: colorScheme.outline, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return _buildTaskCard(task, colorScheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, ColorScheme scheme) {
    Color priorityColor;
    if (task.priority == 'High') {
      priorityColor = Colors.red;
    } else if (task.priority == 'Medium') {
      priorityColor = Colors.orange;
    } else {
      priorityColor = Colors.green;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outline.withOpacity(0.12)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: task.isCompleted ? Colors.green : scheme.primary,
          ),
          onPressed: () {
            ref.read(taskProvider.notifier).toggleCompleted(task.id);
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
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
                style: const TextStyle(fontSize: 12),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: priorityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    task.priority,
                    style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Due: ${DateFormat('dd MMM yyyy').format(task.dueDate)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Text(
                  '#${task.category}',
                  style: TextStyle(fontSize: 10, color: scheme.secondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showAddTaskSheet(editingTask: task),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
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
