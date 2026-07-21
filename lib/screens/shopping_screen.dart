import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/shopping_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../models/shopping_item.dart';
import '../models/expense.dart';

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showAddItemSheet({ShoppingItem? editingItem}) {
    if (editingItem != null) {
      _nameController.text = editingItem.name;
      _qtyController.text = editingItem.quantity.toString();
      _priceController.text = editingItem.price.toStringAsFixed(1);
    } else {
      _nameController.clear();
      _qtyController.text = '1';
      _priceController.text = '0.0';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

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
                editingItem == null ? 'Add Shopping Item' : 'Edit Shopping Item',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Price per item',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) return;

                    final qty = int.tryParse(_qtyController.text) ?? 1;
                    final price = double.tryParse(_priceController.text) ?? 0.0;
                    final cost = qty * price;

                    final shoppingNotifier = ref.read(shoppingProvider.notifier);

                    if (editingItem == null) {
                      final item = ShoppingItem(
                        id: const Uuid().v4(),
                        name: name,
                        quantity: qty,
                        price: price,
                        estimatedCost: cost,
                        isPurchased: false,
                      );
                      shoppingNotifier.addItem(item);
                    } else {
                      final item = editingItem.copyWith(
                        name: name,
                        quantity: qty,
                        price: price,
                        estimatedCost: cost,
                      );
                      shoppingNotifier.updateItem(item);
                    }

                    Navigator.pop(context);
                  },
                  child: Text(editingItem == null ? 'Add Item' : 'Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handlePurchaseToggle(ShoppingItem item) async {
    final notifier = ref.read(shoppingProvider.notifier);
    
    if (!item.isPurchased) {
      // Toggle state to purchased
      await notifier.togglePurchased(item.id);
      
      // Prompt user to convert to expense tracker entry
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Move to Expense?'),
              content: Text(
                'Would you like to automatically create an expense entry for "${item.name}" of amount ${ref.read(settingsProvider).currency}${item.estimatedCost.toStringAsFixed(1)}?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('No'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Add expense
                    final exp = Expense(
                      id: const Uuid().v4(),
                      title: item.name,
                      amount: item.estimatedCost,
                      category: 'Shopping',
                      description: 'Purchased from shopping list (Qty: ${item.quantity})',
                      date: DateTime.now(),
                      paymentMethod: 'Cash', // Default
                    );
                    await ref.read(expenseProvider.notifier).addExpense(exp);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Expense logged: ${item.name}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Convert to Expense'),
                )
              ],
            );
          },
        );
      }
    } else {
      // Toggle back to unpurchased
      await notifier.togglePurchased(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(shoppingProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final double totalEstimated = items.fold(0, (sum, i) => sum + i.estimatedCost);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemSheet(),
        child: const Icon(Icons.add_shopping_cart),
      ),
      body: Column(
        children: [
          // Header summary card
          Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Estimated Cost', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        '${settings.currency}${totalEstimated.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
                    child: Text(
                      '${items.where((i) => !i.isPurchased).length} Items Left',
                      style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  )
                ],
              ),
            ),
          ),

          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 64, color: colorScheme.outline.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'Shopping list is empty.',
                          style: TextStyle(color: colorScheme.outline, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildShoppingCard(item, settings.currency, colorScheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingCard(ShoppingItem item, String currency, ColorScheme scheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outline.withOpacity(0.12)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Checkbox(
          value: item.isPurchased,
          activeColor: Colors.green,
          onChanged: (value) => _handlePurchaseToggle(item),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
            color: item.isPurchased ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          'Qty: ${item.quantity} • Price: $currency${item.price.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$currency${item.estimatedCost.toStringAsFixed(1)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: item.isPurchased ? Colors.grey : scheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showAddItemSheet(editingItem: item),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () {
                ref.read(shoppingProvider.notifier).deleteItem(item.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
