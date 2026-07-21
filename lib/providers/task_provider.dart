import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/hive_database.dart';
import '../models/task.dart';

class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier() : super([]) {
    _loadTasks();
  }

  void _loadTasks() {
    final list = HiveDatabase.taskBox.values.toList();
    // Sort tasks: uncompleted first, then by priority, then by due date
    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      // Sort by due date
      return a.dueDate.compareTo(b.dueDate);
    });
    state = list;
  }

  Future<void> addTask(Task task) async {
    await HiveDatabase.taskBox.put(task.id, task);
    _loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await HiveDatabase.taskBox.put(task.id, task);
    _loadTasks();
  }

  Future<void> deleteTask(String id) async {
    await HiveDatabase.taskBox.delete(id);
    _loadTasks();
  }

  Future<void> toggleCompleted(String id) async {
    final task = HiveDatabase.taskBox.get(id);
    if (task != null) {
      final updated = task.copyWith(isCompleted: !task.isCompleted);
      await updateTask(updated);
    }
  }

  void clearAll() {
    state = [];
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  return TaskNotifier();
});

// Task Categories
final taskCategoriesProvider = Provider<List<String>>((ref) => [
      'Personal',
      'Work',
      'Study',
      'Health',
      'Shopping',
    ]);
