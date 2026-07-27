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
    final directory = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(directory.path);

    // Register Adapters
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(IncomeAdapter());
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(SettingsAdapter());

    // Open Boxes
    expenseBox = await Hive.openBox<Expense>('expenses_box');
    incomeBox = await Hive.openBox<Income>('income_box');
    noteBox = await Hive.openBox<Note>('notes_box');
    settingsBox = await Hive.openBox<Settings>('settings_box');

    // Initialize Settings if empty
    if (settingsBox.isEmpty) {
      await settingsBox.put(
        'user_settings',
        Settings(
          isDarkMode: true,
          themeColor: 0xFF2E7D32,
          currency: '₹',
          monthlyBudget: 30000.0,
        ),
      );
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
        themeColor: 0xFF2E7D32,
        currency: '₹',
        monthlyBudget: 30000.0,
      ),
    );
  }
}
