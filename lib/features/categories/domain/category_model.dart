import '../../../core/database/app_database.dart';

class CategoryModel {
  final int id;
  final String key;
  final String name;
  final String? nameId;
  final String icon;
  final String color;
  final int? parentId;
  final bool isDefault;
  final bool isIncome;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.key,
    required this.name,
    this.nameId,
    required this.icon,
    required this.color,
    this.parentId,
    this.isDefault = false,
    this.isIncome = false,
    this.sortOrder = 0,
  });

  factory CategoryModel.fromEntry(CategoryEntry entry) {
    return CategoryModel(
      id: entry.id,
      key: entry.key,
      name: entry.name,
      nameId: entry.nameId,
      icon: entry.icon,
      color: entry.color,
      parentId: entry.parentId,
      isDefault: entry.isDefault,
      isIncome: entry.isIncome,
      sortOrder: entry.sortOrder,
    );
  }

  CategoryModel copyWith({
    int? id,
    String? key,
    String? name,
    String? nameId,
    String? icon,
    String? color,
    int? parentId,
    bool? isDefault,
    bool? isIncome,
    int? sortOrder,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      key: key ?? this.key,
      name: name ?? this.name,
      nameId: nameId ?? this.nameId,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
      isDefault: isDefault ?? this.isDefault,
      isIncome: isIncome ?? this.isIncome,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  String localizedName(String localeCode) {
    if (localeCode == 'id' && nameId != null && nameId!.isNotEmpty) {
      return nameId!;
    }
    return name;
  }
}
