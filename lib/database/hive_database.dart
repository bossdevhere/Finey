import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/shopping_item.dart';
import '../models/task.dart';
import '../models/reminder.dart';
import '../models/note.dart';
import '../models/settings.dart';

class HiveDatabase {
  static late Box<Expense> expenseBox;
  static late Box<Income> incomeBox;
  static late Box<ShoppingItem> shoppingBox;
  static late Box<Task> taskBox;
  static late Box<Reminder> reminderBox;
  static late Box<Note> noteBox;
  static late Box<Settings> settingsBox;

  static Future<void> initialize() async {
    final directory = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(directory.path);

    // Register all Adapters
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(IncomeAdapter());
    Hive.registerAdapter(ShoppingItemAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(ReminderAdapter());
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(SettingsAdapter());

    // Open Boxes
    expenseBox = await Hive.openBox<Expense>('expenses_box');
    incomeBox = await Hive.openBox<Income>('income_box');
    shoppingBox = await Hive.openBox<ShoppingItem>('shopping_box');
    taskBox = await Hive.openBox<Task>('tasks_box');
    reminderBox = await Hive.openBox<Reminder>('reminders_box');
    noteBox = await Hive.openBox<Note>('notes_box');
    settingsBox = await Hive.openBox<Settings>('settings_box');

    // Initialize Settings if empty
    if (settingsBox.isEmpty) {
      await settingsBox.put(
        'user_settings',
        Settings(
          isDarkMode: true, // Default to dark mode for premium look
          themeColor: 0xFF2E7D32, // Forest Green
          currency: '₹', // Rupee by default, user can change
          monthlyBudget: 30000.0,
        ),
      );
    }
  }

  // Clear all databases
  static Future<void> clearAll() async {
    await expenseBox.clear();
    await incomeBox.clear();
    await shoppingBox.clear();
    await taskBox.clear();
    await reminderBox.clear();
    await noteBox.clear();
    // Keep settings or reset them
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
