import 'package:hive/hive.dart';

class ShoppingItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final double estimatedCost;
  final bool isPurchased;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.estimatedCost,
    required this.isPurchased,
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? price,
    double? estimatedCost,
    bool? isPurchased,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }
}

class ShoppingItemAdapter extends TypeAdapter<ShoppingItem> {
  @override
  final int typeId = 3;

  @override
  ShoppingItem read(BinaryReader reader) {
    return ShoppingItem(
      id: reader.readString(),
      name: reader.readString(),
      quantity: reader.readInt(),
      price: reader.readDouble(),
      estimatedCost: reader.readDouble(),
      isPurchased: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingItem obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeInt(obj.quantity);
    writer.writeDouble(obj.price);
    writer.writeDouble(obj.estimatedCost);
    writer.writeBool(obj.isPurchased);
  }
}
