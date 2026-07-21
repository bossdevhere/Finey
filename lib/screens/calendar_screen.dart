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
    List<dynamic> _getEventsForDay(DateTime day) {
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
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
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
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                formatButtonTextStyle: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Agenda: ${DateFormat('dd MMM yyyy').format(_selectedDay!)}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${dayExpenses.length + dayIncomes.length + dayTasks.length} Items',
                  style: TextStyle(color: colorScheme.outline),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: (dayExpenses.isEmpty && dayIncomes.isEmpty && dayTasks.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 48, color: colorScheme.outline.withOpacity(0.5)),
                        const SizedBox(height: 8),
                        Text(
                          'No events or tasks for this day',
                          style: TextStyle(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      if (dayIncomes.isNotEmpty) ...[
                        Text(
                          'Incomes',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        ...dayIncomes.map((inc) => Card(
                              elevation: 0,
                              color: Colors.green.withOpacity(0.05),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.green.withOpacity(0.15))),
                              child: ListTile(
                                leading: const Icon(Icons.arrow_downward, color: Colors.green),
                                title: Text(inc.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(inc.category),
                                trailing: Text(
                                  '+${settings.currency}${inc.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            )),
                        const SizedBox(height: 12),
                      ],
                      if (dayExpenses.isNotEmpty) ...[
                        Text(
                          'Expenses',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        ...dayExpenses.map((exp) => Card(
                              elevation: 0,
                              color: Colors.red.withOpacity(0.05),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.red.withOpacity(0.15))),
                              child: ListTile(
                                leading: const Icon(Icons.arrow_upward, color: Colors.red),
                                title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${exp.category} • ${exp.paymentMethod}'),
                                trailing: Text(
                                  '-${settings.currency}${exp.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            )),
                        const SizedBox(height: 12),
                      ],
                      if (dayTasks.isNotEmpty) ...[
                        Text(
                          'Tasks',
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        ...dayTasks.map((task) => Card(
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: colorScheme.outline.withOpacity(0.15))),
                              child: ListTile(
                                leading: Icon(
                                  task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                                  color: task.isCompleted ? Colors.green : colorScheme.primary,
                                ),
                                title: Text(
                                  task.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                subtitle: Text('${task.category} • Priority: ${task.priority}'),
                              ),
                            )),
                      ]
                    ],
                  ),
          )
        ],
      ),
    );
  }
}
