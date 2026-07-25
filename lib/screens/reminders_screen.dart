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
                      editingReminder == null ? 'Set Alarm / Reminder' : 'Edit Alarm',
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
                        labelText: 'Alarm Title',
                        hintText: 'e.g., Pay electricity bill, Take Medicine',
                        prefixIcon: Icon(Icons.notifications_active_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedType,
                            isExpanded: true,
                            style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(labelText: 'Repeat Mode'),
                            items: ['One Time', 'Daily', 'Weekly', 'Monthly'].map((t) {
                              return DropdownMenuItem(value: t, child: Text(t));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setSheetState(() => _selectedType = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Date & Time Picker Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(color: colorScheme.outline, width: 1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: Icon(Icons.calendar_today_rounded, size: 16, color: colorScheme.onSurface),
                            label: Text(
                              DateFormat('dd MMM yyyy').format(_selectedDateTime),
                              style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _selectedDateTime,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (pickedDate != null) {
                                setSheetState(() {
                                  _selectedDateTime = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    _selectedDateTime.hour,
                                    _selectedDateTime.minute,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(color: colorScheme.outline, width: 1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: Icon(Icons.access_time_rounded, size: 16, color: colorScheme.onSurface),
                            label: Text(
                              TimeOfDay.fromDateTime(_selectedDateTime).format(context),
                              style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            onPressed: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                              );
                              if (pickedTime != null) {
                                setSheetState(() {
                                  _selectedDateTime = DateTime(
                                    _selectedDateTime.year,
                                    _selectedDateTime.month,
                                    _selectedDateTime.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

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
                        child: Text(
                          editingReminder == null ? 'Set Alarm' : 'Save Changes',
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
    final reminders = ref.watch(reminderProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarms & Reminders'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderSheet(),
        elevation: 3,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Set Alarm', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: reminders.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 56, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'No alarms scheduled. Tap + to set one.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final rem = reminders[index];
                  return _buildReminderCard(rem, colorScheme);
                },
              ),
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder, ColorScheme scheme) {
    final hasPassed = reminder.dateTime.isBefore(DateTime.now());
    final statusColor = reminder.isCompleted
        ? scheme.onSurfaceVariant
        : (hasPassed ? const Color(0xFFEF4444) : scheme.primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            reminder.isCompleted
                ? Icons.notifications_off_outlined
                : (hasPassed ? Icons.notifications_active_rounded : Icons.notifications_rounded),
            color: statusColor,
            size: 20,
          ),
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: reminder.isCompleted ? scheme.onSurfaceVariant : scheme.onSurface,
            decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              'Time: ${DateFormat('dd MMM yyyy, hh:mm a').format(reminder.dateTime)}',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            Text(
              'Repeat: ${reminder.type}${reminder.snoozeCount > 0 ? " • Snoozed ${reminder.snoozeCount}x" : ""}',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
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
                child: Text('Snooze', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            IconButton(
              icon: Icon(
                reminder.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: reminder.isCompleted ? const Color(0xFF10B981) : scheme.onSurfaceVariant,
                size: 22,
              ),
              onPressed: () {
                ref.read(reminderProvider.notifier).toggleCompleted(reminder.id);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
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
