import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense.dart';
import '../models/income.dart';

class AddTransactionBottomSheet extends ConsumerStatefulWidget {
  const AddTransactionBottomSheet({super.key});

  @override
  ConsumerState<AddTransactionBottomSheet> createState() => _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends ConsumerState<AddTransactionBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers & Form variables
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _expenseCategory = 'Food';
  String _incomeCategory = 'Salary';
  String _paymentMethod = 'Cash';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    final title = _titleController.text.trim();
    final amtText = _amountController.text.trim();
    if (title.isEmpty || amtText.isEmpty) return;

    final double? amount = double.tryParse(amtText);
    if (amount == null || amount <= 0) return;

    final isExpense = _tabController.index == 0;

    if (isExpense) {
      final exp = Expense(
        id: const Uuid().v4(),
        title: title,
        amount: amount,
        category: _expenseCategory,
        description: _descController.text.trim(),
        date: _selectedDate,
        paymentMethod: _paymentMethod,
      );
      ref.read(expenseProvider.notifier).addExpense(exp);

      // Warning warning! Check budget!
      final settings = ref.read(settingsProvider);
      final currentExpenses = ref.read(expenseProvider);
      final double totalCurrentExpense = currentExpenses
          .where((e) => e.date.year == DateTime.now().year && e.date.month == DateTime.now().month)
          .fold(0, (sum, item) => sum + item.amount);

      if (totalCurrentExpense + amount > settings.monthlyBudget) {
        // Show immediate warning dialog/snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            content: Text(
              '⚠️ Budget Exceeded Alert! Monthly Limit: ${settings.currency}${settings.monthlyBudget.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } else {
      final inc = Income(
        id: const Uuid().v4(),
        title: title,
        amount: amount,
        category: _incomeCategory,
        date: _selectedDate,
        notes: _descController.text.trim(),
      );
      ref.read(incomeProvider.notifier).addIncome(inc);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final expCategories = ref.read(expenseCategoriesProvider);
    final incCategories = ref.read(incomeCategoriesProvider);
    final payMethods = ref.read(paymentMethodsProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Expense', icon: Icon(Icons.arrow_upward, color: Colors.redAccent)),
              Tab(text: 'Income', icon: Icon(Icons.arrow_downward, color: Colors.greenAccent)),
            ],
            indicatorSize: TabBarIndicatorSize.tab,
          ),
          const SizedBox(height: 16),

          // Common Fields
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: ref.read(settingsProvider).currency,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          // Dynamic Tab Fields
          SizedBox(
            height: 180, // Safe scroll height inside sheet
            child: TabBarView(
              controller: _tabController,
              children: [
                // Expense fields
                ListView(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _expenseCategory,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: expCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _expenseCategory = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _paymentMethod,
                            decoration: InputDecoration(
                              labelText: 'Pay Mode',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: payMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _paymentMethod = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descController,
                      decoration: InputDecoration(
                        labelText: 'Description / Note',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),

                // Income fields
                ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _incomeCategory,
                      decoration: InputDecoration(
                        labelText: 'Source Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: incCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _incomeCategory = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descController,
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Date Selection and Save Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(DateFormat('dd MMM').format(_selectedDate)),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: _saveTransaction,
                child: const Text('Save Entry'),
              )
            ],
          ),
        ],
      ),
    );
  }
}
