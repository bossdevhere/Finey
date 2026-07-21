import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  final _titleController = TextEditingController();
  String _selectedType = 'One Time';
  DateTime _selectedDateTime = DateTime.now().add(const Duration(minutes: 5));

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _showAddReminderSheet({Reminder? editingReminder}) {
    if (editingReminder != null) {
      _titleController.text = editingReminder.title;
      _selectedType = editingReminder.type;
      _selectedDateTime = editingReminder.dateTime;
    } else {
      _titleController.clear();
      _selectedType = 'One Time';
      _selectedDateTime = DateTime.now().add(const Duration(minutes: 5));
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
                    editingReminder == null ? 'Schedule New Reminder' : 'Edit Reminder',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Reminder Message',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Repeat Frequency',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ref.read(repeatTypesProvider).map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() => _selectedType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Date & Time'),
                    subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(_selectedDateTime)),
                    leading: const Icon(Icons.alarm),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDateTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null && mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                        );
                        if (time != null) {
                          setSheetState(() {
                            _selectedDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 20),
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

                        final notifier = ref.read(reminderProvider.notifier);

                        if (editingReminder == null) {
                          final rem = Reminder(
                            id: const Uuid().v4(),
                            title: title,
                            type: _selectedType,
                            dateTime: _selectedDateTime,
                            isCompleted: false,
                            repeat: _selectedType != 'One Time',
                            snoozeCount: 0,
                          );
                          notifier.addReminder(rem);
                        } else {
                          final rem = editingReminder.copyWith(
                            title: title,
                            type: _selectedType,
                            dateTime: _selectedDateTime,
                            repeat: _selectedType != 'One Time',
                          );
                          notifier.updateReminder(rem);
                        }
                        Navigator.pop(context);
                      },
                      child: Text(editingReminder == null ? 'Set Alarm' : 'Save Changes'),
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
    final reminders = ref.watch(reminderProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarms & Reminders'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderSheet(),
        child: const Icon(Icons.add_alarm),
      ),
      body: reminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_off_outlined, size: 64, color: colorScheme.outline.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'No alarms scheduled. Tap + to set one.',
                    style: TextStyle(color: colorScheme.outline, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final rem = reminders[index];
                return _buildReminderCard(rem, colorScheme);
              },
            ),
    );
  }

  Widget _buildReminderCard(Reminder reminder, ColorScheme scheme) {
    final hasPassed = reminder.dateTime.isBefore(DateTime.now());
    final statusColor = reminder.isCompleted
        ? Colors.grey
        : (hasPassed ? Colors.red : scheme.primary);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outline.withOpacity(0.12)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(
          reminder.isCompleted
              ? Icons.notifications_none_outlined
              : (hasPassed ? Icons.notifications_active : Icons.notifications_active_outlined),
          color: statusColor,
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: reminder.isCompleted ? Colors.grey : null,
            decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Time: ${DateFormat('dd MMM yyyy, hh:mm a').format(reminder.dateTime)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Frequency: ${reminder.type}${reminder.snoozeCount > 0 ? " • Snoozed ${reminder.snoozeCount} times" : ""}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!reminder.isCompleted && hasPassed)
              TextButton(
                onPressed: () {
                  ref.read(reminderProvider.notifier).snoozeReminder(reminder.id);
                },
                child: const Text('Snooze'),
              ),
            IconButton(
              icon: Icon(
                reminder.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: reminder.isCompleted ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                ref.read(reminderProvider.notifier).toggleCompleted(reminder.id);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () {
                ref.read(reminderProvider.notifier).deleteReminder(reminder.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
