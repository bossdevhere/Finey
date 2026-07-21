import 'package:hive/hive.dart';

class Settings {
  final bool isDarkMode;
  final int themeColor; // Primary theme color ARGB value
  final String currency;
  final double monthlyBudget;

  Settings({
    required this.isDarkMode,
    required this.themeColor,
    required this.currency,
    required this.monthlyBudget,
  });

  Settings copyWith({
    bool? isDarkMode,
    int? themeColor,
    String? currency,
    double? monthlyBudget,
  }) {
    return Settings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      themeColor: themeColor ?? this.themeColor,
      currency: currency ?? this.currency,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }
}

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final int typeId = 7;

  @override
  Settings read(BinaryReader reader) {
    return Settings(
      isDarkMode: reader.readBool(),
      themeColor: reader.readInt(),
      currency: reader.readString(),
      monthlyBudget: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer.writeBool(obj.isDarkMode);
    writer.writeInt(obj.themeColor);
    writer.writeString(obj.currency);
    writer.writeDouble(obj.monthlyBudget);
  }
}
