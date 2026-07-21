import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../database/hive_database.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/shopping_item.dart';
import '../models/task.dart';
import '../models/note.dart';
import '../models/settings.dart';

class ExportService {
  // Export Expenses to CSV file
  static Future<String> exportExpensesToCSV() async {
    final expenses = HiveDatabase.expenseBox.values.toList();

    List<List<dynamic>> rows = [
      ['ID', 'Title', 'Amount', 'Category', 'Description', 'Date', 'Payment Method']
    ];

    for (var exp in expenses) {
      rows.add([
        exp.id,
        exp.title,
        exp.amount,
        exp.category,
        exp.description,
        exp.date.toIso8601String(),
        exp.paymentMethod,
      ]);
    }

    String csvContent = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/PocketLife/Exports');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final file = File('${backupDir.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvContent);
    return file.path;
  }

  // Export Income to CSV file
  static Future<String> exportIncomeToCSV() async {
    final incomes = HiveDatabase.incomeBox.values.toList();

    List<List<dynamic>> rows = [
      ['ID', 'Title', 'Amount', 'Category', 'Date', 'Notes']
    ];

    for (var inc in incomes) {
      rows.add([
        inc.id,
        inc.title,
        inc.amount,
        inc.category,
        inc.date.toIso8601String(),
        inc.notes,
      ]);
    }

    String csvContent = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/PocketLife/Exports');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final file = File('${backupDir.path}/incomes_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvContent);
    return file.path;
  }

  // Export all data to JSON backup
  static Future<String> exportBackupJSON() async {
    final expenses = HiveDatabase.expenseBox.values.map((e) => {
      'id': e.id,
      'title': e.title,
      'amount': e.amount,
      'category': e.category,
      'description': e.description,
      'date': e.date.millisecondsSinceEpoch,
      'paymentMethod': e.paymentMethod,
    }).toList();

    final incomes = HiveDatabase.incomeBox.values.map((i) => {
      'id': i.id,
      'title': i.title,
      'amount': i.amount,
      'category': i.category,
      'date': i.date.millisecondsSinceEpoch,
      'notes': i.notes,
    }).toList();

    final shopping = HiveDatabase.shoppingBox.values.map((s) => {
      'id': s.id,
      'name': s.name,
      'quantity': s.quantity,
      'price': s.price,
      'estimatedCost': s.estimatedCost,
      'isPurchased': s.isPurchased,
    }).toList();

    final tasks = HiveDatabase.taskBox.values.map((t) => {
      'id': t.id,
      'title': t.title,
      'description': t.description,
      'priority': t.priority,
      'dueDate': t.dueDate.millisecondsSinceEpoch,
      'hasReminder': t.hasReminder,
      'isCompleted': t.isCompleted,
      'category': t.category,
    }).toList();

    final notes = HiveDatabase.noteBox.values.map((n) => {
      'id': n.id,
      'title': n.title,
      'content': n.content,
      'color': n.color,
      'isPinned': n.isPinned,
      'isFavorite': n.isFavorite,
      'checklist': n.checklist,
      'checklistChecked': n.checklistChecked,
      'lastModified': n.lastModified.millisecondsSinceEpoch,
    }).toList();

    final settingsObj = HiveDatabase.settingsBox.get('user_settings');
    final settingsMap = settingsObj != null ? {
      'isDarkMode': settingsObj.isDarkMode,
      'themeColor': settingsObj.themeColor,
      'currency': settingsObj.currency,
      'monthlyBudget': settingsObj.monthlyBudget,
    } : null;

    final Map<String, dynamic> backupData = {
      'version': 1,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'expenses': expenses,
      'incomes': incomes,
      'shopping_items': shopping,
      'tasks': tasks,
      'notes': notes,
      'settings': settingsMap,
    };

    final jsonContent = jsonEncode(backupData);

    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/PocketLife/Backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final file = File('${backupDir.path}/backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonContent);
    return file.path;
  }

  // Restore from JSON backup file path
  static Future<bool> restoreBackupJSON(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final content = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(content);

      if (backupData['version'] != 1) return false;

      // Clear current boxes
      await HiveDatabase.clearAll();

      // Restore Expenses
      if (backupData['expenses'] != null) {
        for (var item in backupData['expenses']) {
          final exp = Expense(
            id: item['id'],
            title: item['title'],
            amount: (item['amount'] as num).toDouble(),
            category: item['category'],
            description: item['description'],
            date: DateTime.fromMillisecondsSinceEpoch(item['date']),
            paymentMethod: item['paymentMethod'],
          );
          await HiveDatabase.expenseBox.put(exp.id, exp);
        }
      }

      // Restore Incomes
      if (backupData['incomes'] != null) {
        for (var item in backupData['incomes']) {
          final inc = Income(
            id: item['id'],
            title: item['title'],
            amount: (item['amount'] as num).toDouble(),
            category: item['category'],
            date: DateTime.fromMillisecondsSinceEpoch(item['date']),
            notes: item['notes'],
          );
          await HiveDatabase.incomeBox.put(inc.id, inc);
        }
      }

      // Restore Shopping Items
      if (backupData['shopping_items'] != null) {
        for (var item in backupData['shopping_items']) {
          final s = ShoppingItem(
            id: item['id'],
            name: item['name'],
            quantity: item['quantity'],
            price: (item['price'] as num).toDouble(),
            estimatedCost: (item['estimatedCost'] as num).toDouble(),
            isPurchased: item['isPurchased'],
          );
          await HiveDatabase.shoppingBox.put(s.id, s);
        }
      }

      // Restore Tasks
      if (backupData['tasks'] != null) {
        for (var item in backupData['tasks']) {
          final t = Task(
            id: item['id'],
            title: item['title'],
            description: item['description'],
            priority: item['priority'],
            dueDate: DateTime.fromMillisecondsSinceEpoch(item['dueDate']),
            hasReminder: item['hasReminder'],
            isCompleted: item['isCompleted'],
            category: item['category'],
          );
          await HiveDatabase.taskBox.put(t.id, t);
        }
      }

      // Restore Notes
      if (backupData['notes'] != null) {
        for (var item in backupData['notes']) {
          final n = Note(
            id: item['id'],
            title: item['title'],
            content: item['content'],
            color: item['color'],
            isPinned: item['isPinned'],
            isFavorite: item['isFavorite'],
            checklist: List<String>.from(item['checklist'] ?? []),
            checklistChecked: List<bool>.from(item['checklistChecked'] ?? []),
            lastModified: DateTime.fromMillisecondsSinceEpoch(item['lastModified']),
          );
          await HiveDatabase.noteBox.put(n.id, n);
        }
      }

      // Restore Settings
      if (backupData['settings'] != null) {
        final item = backupData['settings'];
        final s = Settings(
          isDarkMode: item['isDarkMode'] ?? true,
          themeColor: item['themeColor'] ?? 0xFF6200EE,
          currency: item['currency'] ?? '₹',
          monthlyBudget: (item['monthlyBudget'] as num?)?.toDouble() ?? 30000.0,
        );
        await HiveDatabase.settingsBox.put('user_settings', s);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get list of local backups
  static Future<List<File>> getLocalBackups() async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/PocketLife/Backups');
    if (!await backupDir.exists()) return [];

    final list = backupDir.listSync();
    return list
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync())); // Newest first
  }
}
