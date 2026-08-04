import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/settings_provider.dart';
import '../models/transaction_item.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedFilter = 'Month'; // 'Day', 'Week', 'Month', 'All'
  String? _selectedMonthKey;

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider);
    final incomes = ref.watch(incomeProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Combine all activities strongly typed
    final allTransactions = <TransactionItem>[...expenses, ...incomes];

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

    final selectedKey = (sortedMonthKeys.contains(_selectedMonthKey))
        ? _selectedMonthKey!
        : sortedMonthKeys.first;

    // Filter transactions based on selected filter
    final now = DateTime.now();
    List<TransactionItem> filteredTransactions = [];

    if (_selectedFilter == 'Day') {
      filteredTransactions = allTransactions.where((tx) {
        return tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day;
      }).toList();
    } else if (_selectedFilter == 'Week') {
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final startOfWeek = todayMidnight.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      filteredTransactions = allTransactions.where((tx) {
        return !tx.date.isBefore(startOfWeek) && tx.date.isBefore(endOfWeek);
      }).toList();
    } else if (_selectedFilter == 'Month') {
      filteredTransactions = allTransactions.where((tx) {
        return DateFormat('MMMM yyyy').format(tx.date) == selectedKey;
      }).toList();
    } else {
      filteredTransactions = List.from(allTransactions);
    }

    filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

    // Calculate summary for filtered set
    double totalIncome = 0;
    double totalExpense = 0;

    for (final tx in filteredTransactions) {
      if (tx.isExpense) {
        totalExpense += tx.amount;
      } else {
        totalIncome += tx.amount;
      }
    }

    final netMonth = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills & Summary Container
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.outline, width: 1),
                ),
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    // Timeframe Filter Buttons: Day, Week, Month, All
                    _buildFilterSelector(colorScheme),
                    const SizedBox(height: 16),

                    // Secondary Sub-filter Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getFilterTitle(now, selectedKey),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (_selectedFilter == 'Month')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: DropdownButton<String>(
                              value: selectedKey,
                              underline: const SizedBox(),
                              icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurface),
                              dropdownColor: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              items: sortedMonthKeys.map((key) {
                                return DropdownMenuItem<String>(
                                  value: key,
                                  child: Text(
                                    key,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedMonthKey = val;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                    Divider(height: 24, color: colorScheme.outline),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem('Income', '+${settings.currency}${totalIncome.toStringAsFixed(0)}', const Color(0xFF10B981), colorScheme),
                        _buildSummaryItem('Expense', '-${settings.currency}${totalExpense.toStringAsFixed(0)}', const Color(0xFFEF4444), colorScheme),
                        _buildSummaryItem('Net', '${settings.currency}${netMonth.toStringAsFixed(0)}', netMonth >= 0 ? const Color(0xFF6366F1) : const Color(0xFFF97316), colorScheme),
                      ],
                    )
                  ],
                ),
              ),
            ),

            // Transactions List
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(
                      child: Text(
                        'No transactions found for this filter',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final item = filteredTransactions[index];
                        final isExpense = item.isExpense;
                        final color = isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981);
                        final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(item.date);
                        final desc = item.noteOrDescription;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(color: colorScheme.outline, width: 1),
                            ),
                            child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                color: color,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: colorScheme.onSurface),
                            ),
                            subtitle: Text(
                              '$dateStr ${desc.isNotEmpty ? "• $desc" : ""}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                            trailing: Text(
                              '${isExpense ? "-" : "+"}${settings.currency}${item.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: color,
                              ),
                            ),
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: colorScheme.surface,
                                  title: Text('Delete Entry?', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                  content: Text('Do you want to permanently delete this entry?', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.error,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        if (isExpense) {
                                          ref.read(expenseProvider.notifier).deleteExpense(item.id);
                                        } else {
                                          ref.read(incomeProvider.notifier).deleteIncome(item.id);
                                        }
                                      },
                                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSelector(ColorScheme colorScheme) {
    final filters = ['Day', 'Week', 'Month', 'All'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = f;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFilterTitle(DateTime now, String selectedKey) {
    if (_selectedFilter == 'Day') {
      return 'Today (${DateFormat('dd MMM').format(now)})';
    } else if (_selectedFilter == 'Week') {
      return 'This Week (Mon - Sun)';
    } else if (_selectedFilter == 'Month') {
      return 'Selected Month';
    } else {
      return 'All Transactions';
    }
  }

  Widget _buildSummaryItem(String label, String value, Color accentColor, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: accentColor,
          ),
        ),
      ],
    );
  }
}
