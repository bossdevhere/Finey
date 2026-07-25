import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  bool _isSameDayWithoutTime(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider);
    final incomes = ref.watch(incomeProvider);
    final tasks = ref.watch(taskProvider);
    final settings = ref.watch(settingsProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filter data for selected day
    final dayExpenses = expenses.where((e) => _isSameDayWithoutTime(e.date, _selectedDay!)).toList();
    final dayIncomes = incomes.where((i) => _isSameDayWithoutTime(i.date, _selectedDay!)).toList();
    final dayTasks = tasks.where((t) => _isSameDayWithoutTime(t.dueDate, _selectedDay!)).toList();

    // Get events for markers
    List<dynamic> getEventsForDay(DateTime day) {
      final List<dynamic> events = [];
      events.addAll(expenses.where((e) => _isSameDayWithoutTime(e.date, day)));
      events.addAll(incomes.where((i) => _isSameDayWithoutTime(i.date, day)));
      events.addAll(tasks.where((t) => _isSameDayWithoutTime(t.dueDate, day)));
      return events;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Planner'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outline, width: 1),
              ),
              padding: const EdgeInsets.all(8),
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                eventLoader: getEventsForDay,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
                  selectedDecoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                  markerDecoration: BoxDecoration(
                    color: colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonDecoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  formatButtonTextStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                  titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Agenda: ${DateFormat('dd MMM yyyy').format(_selectedDay!)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${dayExpenses.length + dayIncomes.length + dayTasks.length} Items',
                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: (dayExpenses.isEmpty && dayIncomes.isEmpty && dayTasks.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_note_rounded, size: 48, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
                          const SizedBox(height: 8),
                          Text(
                            'No events or tasks for this day',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        if (dayIncomes.isNotEmpty) ...[
                          Text(
                            'INCOMES',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF10B981), fontSize: 12, letterSpacing: 1.1),
                          ),
                          const SizedBox(height: 6),
                          ...dayIncomes.map((inc) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: colorScheme.outline, width: 1),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0x1F10B981),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 18),
                                  ),
                                  title: Text(inc.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: colorScheme.onSurface)),
                                  subtitle: Text(inc.category, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                  trailing: Text(
                                    '+${settings.currency}${inc.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                                ),
                              )),
                          const SizedBox(height: 12),
                        ],
                        if (dayExpenses.isNotEmpty) ...[
                          Text(
                            'EXPENSES',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFEF4444), fontSize: 12, letterSpacing: 1.1),
                          ),
                          const SizedBox(height: 6),
                          ...dayExpenses.map((exp) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: colorScheme.outline, width: 1),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0x1FEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFFEF4444), size: 18),
                                  ),
                                  title: Text(exp.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: colorScheme.onSurface)),
                                  subtitle: Text('${exp.category} • ${exp.paymentMethod}', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                  trailing: Text(
                                    '-${settings.currency}${exp.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                                ),
                              )),
                          const SizedBox(height: 12),
                        ],
                        if (dayTasks.isNotEmpty) ...[
                          Text(
                            'TASKS',
                            style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.primary, fontSize: 12, letterSpacing: 1.1),
                          ),
                          const SizedBox(height: 6),
                          ...dayTasks.map((task) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: colorScheme.outline, width: 1),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    color: task.isCompleted ? const Color(0xFF10B981) : colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  title: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: task.isCompleted ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  subtitle: Text('${task.category} • Priority: ${task.priority}', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                ),
                              )),
                        ]
                      ],
                    ),
            )
          ],
        ),
      ),
    );
  }
}
