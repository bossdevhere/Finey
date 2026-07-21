import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/hive_database.dart';
import '../models/reminder.dart';
import '../services/notification_service.dart';

class ReminderNotifier extends StateNotifier<List<Reminder>> {
  ReminderNotifier() : super([]) {
    _loadReminders();
  }

  void _loadReminders() {
    final list = HiveDatabase.reminderBox.values.toList();
    // Sort reminders: active ones with nearest dates first, then completed ones
    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return a.dateTime.compareTo(b.dateTime);
    });
    state = list;
  }

  Future<void> addReminder(Reminder reminder) async {
    await HiveDatabase.reminderBox.put(reminder.id, reminder);
    _loadReminders();

    // Schedule notification
    await NotificationService.scheduleNotification(
      id: reminder.id.hashCode,
      title: 'Reminder: ${reminder.title}',
      body: 'Time for your scheduled reminder: ${reminder.title} (${reminder.type})',
      scheduledTime: reminder.dateTime,
      repeatType: reminder.type,
    );
  }

  Future<void> updateReminder(Reminder reminder) async {
    await HiveDatabase.reminderBox.put(reminder.id, reminder);
    _loadReminders();

    // Cancel old and schedule updated notification
    await NotificationService.cancelNotification(reminder.id.hashCode);
    if (!reminder.isCompleted) {
      await NotificationService.scheduleNotification(
        id: reminder.id.hashCode,
        title: 'Reminder: ${reminder.title}',
        body: 'Time for your scheduled reminder: ${reminder.title} (${reminder.type})',
        scheduledTime: reminder.dateTime,
        repeatType: reminder.type,
      );
    }
  }

  Future<void> deleteReminder(String id) async {
    await HiveDatabase.reminderBox.delete(id);
    _loadReminders();

    // Cancel notification
    await NotificationService.cancelNotification(id.hashCode);
  }

  Future<void> toggleCompleted(String id) async {
    final reminder = HiveDatabase.reminderBox.get(id);
    if (reminder != null) {
      final updated = reminder.copyWith(isCompleted: !reminder.isCompleted);
      await updateReminder(updated);
    }
  }

  Future<void> snoozeReminder(String id) async {
    final reminder = HiveDatabase.reminderBox.get(id);
    if (reminder != null) {
      final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
      final updated = reminder.copyWith(
        dateTime: snoozeTime,
        snoozeCount: reminder.snoozeCount + 1,
      );
      await updateReminder(updated);
    }
  }

  void clearAll() {
    state = [];
  }
}

final reminderProvider =
    StateNotifierProvider<ReminderNotifier, List<Reminder>>((ref) {
  return ReminderNotifier();
});

// Reminder Categories
final reminderCategoriesProvider = Provider<List<String>>((ref) => [
      'Pay Electricity Bill',
      'College Fees',
      'Gym Renewal',
      'Insurance',
      'Medicine',
      'Birthday',
      'Other',
    ]);

// Repeat types
final repeatTypesProvider = Provider<List<String>>((ref) => [
      'One Time',
      'Daily',
      'Weekly',
      'Monthly',
      'Yearly',
    ]);
