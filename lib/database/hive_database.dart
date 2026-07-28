import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/note.dart';
import '../models/settings.dart';

class HiveDatabase {
  static late Box<Expense> expenseBox;
  static late Box<Income> incomeBox;
  static late Box<Note> noteBox;
  static late Box<Settings> settingsBox;

  static Future<void> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(directory.path);

      // Safely Register Adapters
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ExpenseAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(IncomeAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(NoteAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(SettingsAdapter());
      }

      // Open Boxes with fallback error handling
      expenseBox = await _openSafeBox<Expense>('expenses_box');
      incomeBox = await _openSafeBox<Income>('income_box');
      noteBox = await _openSafeBox<Note>('notes_box');
      settingsBox = await _openSafeBox<Settings>('settings_box');

      // Initialize Settings if empty
      if (settingsBox.isEmpty) {
        await settingsBox.put(
          'user_settings',
          Settings(
            isDarkMode: true,
            themeColor: 0xFF10B981,
            currency: '₹',
            monthlyBudget: 30000.0,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Hive database initialization warning: $e');
      }
    }
  }

  static Future<Box<T>> _openSafeBox<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } catch (e) {
      // In case of binary box corruption, delete corrupt file and reopen
      await Hive.deleteBoxFromDisk(name);
      return await Hive.openBox<T>(name);
    }
  }

  // Clear all databases
  static Future<void> clearAll() async {
    await expenseBox.clear();
    await incomeBox.clear();
    await noteBox.clear();
    await settingsBox.put(
      'user_settings',
      Settings(
        isDarkMode: true,
        themeColor: 0xFF10B981,
        currency: '₹',
        monthlyBudget: 30000.0,
      ),
    );
  }
}
