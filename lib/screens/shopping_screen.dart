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
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final bottomPadding = MediaQuery.of(context).padding.bottom;

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
                  editingItem == null ? 'Add Shopping Item' : 'Edit Shopping Item',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'e.g., Milk, Groceries, New Shoes',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Price',
                          prefixText: '${ref.read(settingsProvider).currency} ',
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 0,
                    ),
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;

                      final qty = int.tryParse(_qtyController.text) ?? 1;
                      final price = double.tryParse(_priceController.text) ?? 0.0;
                      final notifier = ref.read(shoppingProvider.notifier);

                      if (editingItem == null) {
                        final item = ShoppingItem(
                          id: const Uuid().v4(),
                          name: name,
                          quantity: qty,
                          price: price,
                          estimatedCost: qty * price,
                          isPurchased: false,
                        );
                        notifier.addItem(item);
                      } else {
                        final item = editingItem.copyWith(
                          name: name,
                          quantity: qty,
                          price: price,
                          estimatedCost: qty * price,
                        );
                        notifier.updateItem(item);
                      }
                      Navigator.pop(context);
                    },
                    child: Text(
                      editingItem == null ? 'Add Item' : 'Save Changes',
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
  }

  void _handlePurchaseToggle(ShoppingItem item) async {
    final notifier = ref.read(shoppingProvider.notifier);

    if (!item.isPurchased) {
      await notifier.togglePurchased(item.id);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            final colorScheme = Theme.of(context).colorScheme;
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Item Purchased!', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              content: Text(
                'Would you like to log "${item.name}" (${ref.read(settingsProvider).currency}${item.estimatedCost.toStringAsFixed(1)}) as a financial expense?',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Skip', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final exp = Expense(
                      id: const Uuid().v4(),
                      title: item.name,
                      amount: item.estimatedCost,
                      category: 'Shopping',
                      description: 'Purchased from shopping list (Qty: ${item.quantity})',
                      date: DateTime.now(),
                      paymentMethod: 'Cash',
                    );
                    await ref.read(expenseProvider.notifier).addExpense(exp);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Expense logged: ${item.name}'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  child: const Text('Log Expense', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            );
          },
        );
      }
    } else {
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemSheet(),
        elevation: 3,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header summary card
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.outline, width: 1),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Total',
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${settings.currency}${totalEstimated.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${items.where((i) => i.isPurchased).length}/${items.length} Done',
                        style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.primary, fontSize: 13),
                      ),
                    ),
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
                          Icon(Icons.shopping_bag_outlined, size: 56, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text(
                            'Shopping list is empty.',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildShoppingCard(item, settings.currency, colorScheme);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShoppingCard(ShoppingItem item, String currency, ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Checkbox(
          value: item.isPurchased,
          activeColor: const Color(0xFF10B981),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          onChanged: (value) => _handlePurchaseToggle(item),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
            color: item.isPurchased ? scheme.onSurfaceVariant : scheme.onSurface,
          ),
        ),
        subtitle: Text(
          'Qty: ${item.quantity} • Price: $currency${item.price.toStringAsFixed(1)}',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$currency${item.estimatedCost.toStringAsFixed(1)}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: item.isPurchased ? scheme.onSurfaceVariant : scheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 18, color: scheme.onSurfaceVariant),
              onPressed: () => _showAddItemSheet(editingItem: item),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
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
