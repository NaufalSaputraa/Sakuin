import 'package:json_annotation/json_annotation.dart';

part 'budget_model.g.dart';

@JsonEnum()
enum BudgetType {
  limit, // "Do not spend more than X"
  target, // "Target saving X"
  expected; // "Expected spending X"

  static BudgetType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'target':
        return BudgetType.target;
      case 'expected':
        return BudgetType.expected;
      case 'limit':
      default:
        return BudgetType.limit;
    }
  }

  String toDbString() => name;
}

@JsonSerializable()
class BudgetModel {
  final int id;
  final String name;
  final BudgetType budgetType;
  final double amount;
  final String period; // 'daily' | 'weekly' | 'monthly' | 'yearly'
  final int? categoryId;
  final int? walletId;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  const BudgetModel({
    required this.id,
    required this.name,
    required this.budgetType,
    required this.amount,
    this.period = 'monthly',
    this.categoryId,
    this.walletId,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) => _$BudgetModelFromJson(json);

  Map<String, dynamic> toJson() => _$BudgetModelToJson(this);

  BudgetModel copyWith({
    int? id,
    String? name,
    BudgetType? budgetType,
    double? amount,
    String? period,
    int? categoryId,
    int? walletId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      budgetType: budgetType ?? this.budgetType,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
