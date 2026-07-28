import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense.dart';
import '../models/income.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _TimelinePoint {
  final String label;
  final double expense;
  final double income;

  _TimelinePoint({
    required this.label,
    required this.expense,
    required this.income,
  });
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _selectedPeriod = 'Monthly'; // Daily, Weekly, Monthly, Yearly

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider);
    final incomes = ref.watch(incomeProvider);
    final settings = ref.watch(settingsProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filtered data based on selection
    final filteredExpenses = _filterExpenses(expenses);
    final filteredIncomes = _filterIncomes(incomes);

    // Totals
    final double totalExpense = filteredExpenses.fold(0, (sum, item) => sum + item.amount);
    final double totalIncome = filteredIncomes.fold(0, (sum, item) => sum + item.amount);
    final double netSavings = totalIncome - totalExpense;

    // Stat: Average Daily Expense
    final double avgDailyExpense = _calculateAvgDaily(filteredExpenses);

    // Stat: Highest spending category
    final categoryTotals = _getCategoryTotals(filteredExpenses);
    String highestCategory = 'N/A';
    double highestAmt = 0.0;
    categoryTotals.forEach((cat, amt) {
      if (amt > highestAmt) {
        highestAmt = amt;
        highestCategory = cat;
      }
    });

    // Timeline data points for Bar Chart & Line Chart
    final timelinePoints = _getTimelinePoints(expenses, incomes);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Analytics'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Period Selector Segmented Button
            _buildPeriodSelector(colorScheme),
            const SizedBox(height: 20),

            // Financial Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Income',
                    '${settings.currency}${totalIncome.toStringAsFixed(0)}',
                    const Color(0xFF10B981),
                    Icons.arrow_downward_rounded,
                    colorScheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Expenses',
                    '${settings.currency}${totalExpense.toStringAsFixed(0)}',
                    const Color(0xFFEF4444),
                    Icons.arrow_upward_rounded,
                    colorScheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Net Savings',
              '${settings.currency}${netSavings.toStringAsFixed(0)}',
              netSavings >= 0 ? const Color(0xFF6366F1) : const Color(0xFFF97316),
              Icons.savings_outlined,
              colorScheme,
              isFullWidth: true,
            ),
            const SizedBox(height: 24),

            // 1. Bar Chart: Income vs Expense Comparison
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Income & Expense Comparison', colorScheme),
                _buildChartLegend(colorScheme),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline, width: 1),
              ),
              padding: const EdgeInsets.all(20.0),
              child: _buildBarChart(timelinePoints, settings.currency, colorScheme),
            ),
            const SizedBox(height: 24),

            // 2. Pie Chart: Category breakdown
            _sectionTitle('Category Distribution', colorScheme),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline, width: 1),
              ),
              padding: const EdgeInsets.all(20.0),
              child: categoryTotals.isEmpty
                  ? SizedBox(
                      height: 180,
                      child: Center(
                        child: Text(
                          'No expense data to analyze',
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 180,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 36,
                                sections: _buildPieSections(categoryTotals, colorScheme),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: categoryTotals.entries.map((entry) {
                              final color = _getCategoryColor(entry.key, colorScheme);
                              final pct = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${entry.key} (${pct.toStringAsFixed(0)}%)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // 3. Line Chart: Spending & Income Trends
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Financial Trends', colorScheme),
                _buildChartLegend(colorScheme),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline, width: 1),
              ),
              padding: const EdgeInsets.all(20.0),
              child: _buildLineChart(timelinePoints, settings.currency, colorScheme),
            ),
            const SizedBox(height: 24),

            // Key Insights Card
            _sectionTitle('Key Insights', colorScheme),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline, width: 1),
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildInsightRow('Highest Spending Category', highestCategory, colorScheme),
                  Divider(color: colorScheme.outline, height: 20),
                  _buildInsightRow('Average Daily Spending', '${settings.currency}${avgDailyExpense.toStringAsFixed(1)}', colorScheme),
                  Divider(color: colorScheme.outline, height: 20),
                  _buildInsightRow('Current Savings Margin', '${settings.currency}${netSavings.toStringAsFixed(0)}', colorScheme),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(ColorScheme colorScheme) {
    return Row(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text('Income', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text('Expense', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }

  Widget _buildBarChart(List<_TimelinePoint> points, String currency, ColorScheme scheme) {
    if (points.every((p) => p.expense == 0 && p.income == 0)) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'No activity recorded for this period',
            style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    double maxY = 0;
    for (var p in points) {
      if (p.expense > maxY) maxY = p.expense;
      if (p.income > maxY) maxY = p.income;
    }
    if (maxY == 0) maxY = 100;
    maxY = maxY * 1.2;

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final isIncome = rodIndex == 0;
                  final type = isIncome ? 'Income' : 'Expense';
                  return BarTooltipItem(
                    '$type: $currency${rod.toY.toStringAsFixed(0)}',
                    TextStyle(
                      color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < points.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          points[idx].label,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(points.length, (i) {
              final p = points[i];
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: p.income,
                    color: const Color(0xFF10B981),
                    width: 10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: p.expense,
                    color: const Color(0xFFEF4444),
                    width: 10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<_TimelinePoint> points, String currency, ColorScheme scheme) {
    if (points.every((p) => p.expense == 0 && p.income == 0)) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'No trend data logged for this period',
            style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    double maxY = 0;
    for (var p in points) {
      if (p.expense > maxY) maxY = p.expense;
      if (p.income > maxY) maxY = p.income;
    }
    if (maxY == 0) maxY = 100;
    maxY = maxY * 1.2;

    final incomeSpots = List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i].income));
    final expenseSpots = List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i].expense));

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0, bottom: 4.0),
        child: LineChart(
          LineChartData(
            clipData: const FlClipData.all(),
            minX: 0,
            maxX: (points.length - 1).toDouble(),
            maxY: maxY,
            minY: 0,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final isIncome = spot.barIndex == 1; // 0: expense, 1: income
                    final label = isIncome ? 'Income' : 'Expense';
                    final color = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                    return LineTooltipItem(
                      '$label: $currency${spot.y.toStringAsFixed(0)}',
                      TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                    );
                  }).toList();
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: scheme.outline.withValues(alpha: 0.2),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < points.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          points[idx].label,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              // Expenses Line (Red)
              LineChartBarData(
                spots: expenseSpots,
                isCurved: true,
                color: const Color(0xFFEF4444),
                barWidth: 3.5,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                ),
              ),
              // Incomes Line (Green)
              LineChartBarData(
                spots: incomeSpots,
                isCurved: true,
                color: const Color(0xFF10B981),
                barWidth: 3.5,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(ColorScheme colorScheme) {
    final periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: Row(
        children: periods.map((p) {
          final isSelected = _selectedPeriod == p;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = p;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  p,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatCard(String title, String val, Color accentColor, IconData icon, ColorScheme colorScheme, {bool isFullWidth = false}) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                val,
                style: TextStyle(
                  fontSize: isFullWidth ? 26 : 22,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String title, String val, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            val,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: colorScheme.onSurface,
      ),
    );
  }

  // Helper calculation functions
  DateTime _getStartOfWeek(DateTime now) {
    final todayMidnight = DateTime(now.year, now.month, now.day);
    return todayMidnight.subtract(Duration(days: now.weekday - 1));
  }

  DateTime _getEndOfWeek(DateTime now) {
    return _getStartOfWeek(now).add(const Duration(days: 7));
  }

  List<Expense> _filterExpenses(List<Expense> list) {
    final now = DateTime.now();
    if (_selectedPeriod == 'Daily') {
      return list.where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day).toList();
    } else if (_selectedPeriod == 'Weekly') {
      final start = _getStartOfWeek(now);
      final end = _getEndOfWeek(now);
      return list.where((e) => !e.date.isBefore(start) && e.date.isBefore(end)).toList();
    } else if (_selectedPeriod == 'Monthly') {
      return list.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    } else {
      return list.where((e) => e.date.year == now.year).toList();
    }
  }

  List<Income> _filterIncomes(List<Income> list) {
    final now = DateTime.now();
    if (_selectedPeriod == 'Daily') {
      return list.where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day).toList();
    } else if (_selectedPeriod == 'Weekly') {
      final start = _getStartOfWeek(now);
      final end = _getEndOfWeek(now);
      return list.where((e) => !e.date.isBefore(start) && e.date.isBefore(end)).toList();
    } else if (_selectedPeriod == 'Monthly') {
      return list.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    } else {
      return list.where((e) => e.date.year == now.year).toList();
    }
  }

  List<_TimelinePoint> _getTimelinePoints(List<Expense> expenses, List<Income> incomes) {
    final now = DateTime.now();
    final List<_TimelinePoint> points = [];

    if (_selectedPeriod == 'Daily') {
      // 6 time slots for Today: 12 AM, 4 AM, 8 AM, 12 PM, 4 PM, 8 PM
      final slots = ['12 AM', '4 AM', '8 AM', '12 PM', '4 PM', '8 PM'];
      final expTotals = List<double>.filled(6, 0.0);
      final incTotals = List<double>.filled(6, 0.0);

      final todayExp = expenses.where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day);
      for (var e in todayExp) {
        final slotIndex = (e.date.hour / 4).floor().clamp(0, 5);
        expTotals[slotIndex] += e.amount;
      }

      final todayInc = incomes.where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day);
      for (var e in todayInc) {
        final slotIndex = (e.date.hour / 4).floor().clamp(0, 5);
        incTotals[slotIndex] += e.amount;
      }

      for (int i = 0; i < 6; i++) {
        points.add(_TimelinePoint(
          label: slots[i],
          expense: expTotals[i],
          income: incTotals[i],
        ));
      }
    } else if (_selectedPeriod == 'Weekly') {
      // Mon..Sun of current week
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final expTotals = List<double>.filled(7, 0.0);
      final incTotals = List<double>.filled(7, 0.0);

      final start = _getStartOfWeek(now);
      final end = _getEndOfWeek(now);

      for (var e in expenses) {
        if (!e.date.isBefore(start) && e.date.isBefore(end)) {
          final idx = (e.date.weekday - 1).clamp(0, 6);
          expTotals[idx] += e.amount;
        }
      }

      for (var e in incomes) {
        if (!e.date.isBefore(start) && e.date.isBefore(end)) {
          final idx = (e.date.weekday - 1).clamp(0, 6);
          incTotals[idx] += e.amount;
        }
      }

      for (int i = 0; i < 7; i++) {
        points.add(_TimelinePoint(
          label: days[i],
          expense: expTotals[i],
          income: incTotals[i],
        ));
      }
    } else if (_selectedPeriod == 'Monthly') {
      // 4 Weeks in current month: W1 (1-7), W2 (8-14), W3 (15-21), W4 (22+)
      final weeks = ['W1 (1-7)', 'W2 (8-14)', 'W3 (15-21)', 'W4 (22+)'];
      final expTotals = List<double>.filled(4, 0.0);
      final incTotals = List<double>.filled(4, 0.0);

      final monthExp = expenses.where((e) => e.date.year == now.year && e.date.month == now.month);
      for (var e in monthExp) {
        int idx = 0;
        if (e.date.day <= 7) {
          idx = 0;
        } else if (e.date.day <= 14) {
          idx = 1;
        } else if (e.date.day <= 21) {
          idx = 2;
        } else {
          idx = 3;
        }
        expTotals[idx] += e.amount;
      }

      final monthInc = incomes.where((e) => e.date.year == now.year && e.date.month == now.month);
      for (var e in monthInc) {
        int idx = 0;
        if (e.date.day <= 7) {
          idx = 0;
        } else if (e.date.day <= 14) {
          idx = 1;
        } else if (e.date.day <= 21) {
          idx = 2;
        } else {
          idx = 3;
        }
        incTotals[idx] += e.amount;
      }

      for (int i = 0; i < 4; i++) {
        points.add(_TimelinePoint(
          label: weeks[i],
          expense: expTotals[i],
          income: incTotals[i],
        ));
      }
    } else {
      // Yearly: 12 months
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final expTotals = List<double>.filled(12, 0.0);
      final incTotals = List<double>.filled(12, 0.0);

      final yearExp = expenses.where((e) => e.date.year == now.year);
      for (var e in yearExp) {
        final idx = (e.date.month - 1).clamp(0, 11);
        expTotals[idx] += e.amount;
      }

      final yearInc = incomes.where((e) => e.date.year == now.year);
      for (var e in yearInc) {
        final idx = (e.date.month - 1).clamp(0, 11);
        incTotals[idx] += e.amount;
      }

      for (int i = 0; i < 12; i++) {
        points.add(_TimelinePoint(
          label: months[i],
          expense: expTotals[i],
          income: incTotals[i],
        ));
      }
    }

    return points;
  }

  double _calculateAvgDaily(List<Expense> list) {
    if (list.isEmpty) return 0.0;
    if (_selectedPeriod == 'Daily') return list.fold(0.0, (sum, e) => sum + e.amount);

    final dates = list.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet();
    final total = list.fold(0.0, (sum, e) => sum + e.amount);
    return total / (dates.isEmpty ? 1 : dates.length);
  }

  Map<String, double> _getCategoryTotals(List<Expense> list) {
    final Map<String, double> data = {};
    for (var item in list) {
      data[item.category] = (data[item.category] ?? 0.0) + item.amount;
    }
    return data;
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> totals, ColorScheme scheme) {
    return totals.entries.map((entry) {
      final color = _getCategoryColor(entry.key, scheme);
      return PieChartSectionData(
        value: entry.value,
        title: '',
        color: color,
        radius: 18,
      );
    }).toList();
  }

  Color _getCategoryColor(String category, ColorScheme scheme) {
    switch (category) {
      case 'Food':
        return const Color(0xFFF59E0B);
      case 'Shopping':
        return const Color(0xFF8B5CF6);
      case 'Travel':
        return const Color(0xFF3B82F6);
      case 'Bills':
        return const Color(0xFFEF4444);
      case 'Health':
        return const Color(0xFF10B981);
      case 'Entertainment':
        return const Color(0xFFEC4899);
      case 'Education':
        return const Color(0xFF14B8A6);
      case 'Fuel':
        return const Color(0xFFEAB308);
      default:
        return scheme.onSurfaceVariant;
    }
  }
}
