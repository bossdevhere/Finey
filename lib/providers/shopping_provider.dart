import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/hive_database.dart';
import '../models/shopping_item.dart';

class ShoppingNotifier extends StateNotifier<List<ShoppingItem>> {
  ShoppingNotifier() : super([]) {
    _loadItems();
  }

  void _loadItems() {
    final list = HiveDatabase.shoppingBox.values.toList();
    // Unpurchased items first, then purchased
    list.sort((a, b) {
      if (a.isPurchased == b.isPurchased) return a.name.compareTo(b.name);
      return a.isPurchased ? 1 : -1;
    });
    state = list;
  }

  Future<void> addItem(ShoppingItem item) async {
    await HiveDatabase.shoppingBox.put(item.id, item);
    _loadItems();
  }

  Future<void> updateItem(ShoppingItem item) async {
    await HiveDatabase.shoppingBox.put(item.id, item);
    _loadItems();
  }

  Future<void> deleteItem(String id) async {
    await HiveDatabase.shoppingBox.delete(id);
    _loadItems();
  }

  Future<void> togglePurchased(String id) async {
    final item = HiveDatabase.shoppingBox.get(id);
    if (item != null) {
      final updated = item.copyWith(isPurchased: !item.isPurchased);
      await updateItem(updated);
    }
  }

  void clearAll() {
    state = [];
  }
}

final shoppingProvider =
    StateNotifierProvider<ShoppingNotifier, List<ShoppingItem>>((ref) {
  return ShoppingNotifier();
});
