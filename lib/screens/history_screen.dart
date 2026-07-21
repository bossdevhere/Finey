import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense.dart';
import '../models/income.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String? _selectedMonthKey;

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider);
    final incomes = ref.watch(incomeProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    // Combine all activities
    final allTransactions = <dynamic>[...expenses, ...incomes];

    // Group available months for the dropdown selection
    final Map<String, DateTime> monthYears = {};
    for (final tx in allTransactions) {
      final key = DateFormat('MMMM yyyy').format(tx.date);
      if (!monthYears.containsKey(key)) {
        monthYears[key] = DateTime(tx.date.year, tx.date.month);
      }
    }

    final sortedMonthKeys = monthYears.keys.toList()
      ..sort((a, b) => monthYears[b]!.compareTo(monthYears[a]!));

    if (sortedMonthKeys.isEmpty) {
      final curKey = DateFormat('MMMM yyyy').format(DateTime.now());
      sortedMonthKeys.add(curKey);
      monthYears[curKey] = DateTime(DateTime.now().year, DateTime.now().month);
    }

    final selectedKey = _selectedMonthKey ?? sortedMonthKeys.first;

    // Filter transactions for the selected month
    final monthlyTransactions = allTransactions.where((tx) {
      return DateFormat('MMMM yyyy').format(tx.date) == selectedKey;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Calculate monthly summary
    double totalIncome = 0;
    double totalExpense = 0;

    for (final tx in monthlyTransactions) {
      if (tx is Expense) {
        totalExpense += tx.amount;
      } else if (tx is Income) {
        totalIncome += tx.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Simplified Month Picker & Summary Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Selective Month Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Month:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        DropdownButton<String>(
                          value: selectedKey,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down),
                          borderRadius: BorderRadius.circular(12),
                          items: sortedMonthKeys.map((key) {
                            return DropdownMenuItem<String>(
                              value: key,
                              child: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedMonthKey = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Summary Rows (Reduced text, simple layout)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Income',
                          '${settings.currency}${totalIncome.toStringAsFixed(0)}',
                          Colors.green,
                        ),
                        _buildSummaryItem(
                          'Expenses',
                          '${settings.currency}${totalExpense.toStringAsFixed(0)}',
                          Colors.red,
                        ),
                        _buildSummaryItem(
                          'Net',
                          '${settings.currency}${(totalIncome - totalExpense).toStringAsFixed(0)}',
                          (totalIncome - totalExpense) >= 0 ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Simplified Activity List
          Expanded(
            child: monthlyTransactions.isEmpty
                ? Center(
                    child: Text(
                      'No activities for this month.',
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: monthlyTransactions.length,
                    itemBuilder: (context, index) {
                      final item = monthlyTransactions[index];
                      final isExpense = item is Expense;
                      final dateStr = DateFormat('dd MMM').format(item.date);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor: isExpense
                                ? Colors.red.withOpacity(0.08)
                                : Colors.green.withOpacity(0.08),
                            radius: 16,
                            child: Icon(
                              isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isExpense ? Colors.red : Colors.green,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            item.category,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '$dateStr ${item.description.isNotEmpty ? "• ${item.description}" : ""}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            '${isExpense ? "-" : "+"}${settings.currency}${item.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isExpense ? Colors.red : Colors.green,
                            ),
                          ),
                          onLongPress: () {
                            // Quick option to delete
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Entry?'),
                                content: const Text('Do you want to permanently delete this entry?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.error,
                                      foregroundColor: theme.colorScheme.onError,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      if (isExpense) {
                                        ref.read(expenseProvider.notifier).deleteExpense(item.id);
                                      } else {
                                        ref.read(incomeProvider.notifier).deleteIncome(item.id);
                                      }
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
