// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BudgetModel _$BudgetModelFromJson(Map<String, dynamic> json) => BudgetModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      budgetType: $enumDecode(_$BudgetTypeEnumMap, json['budgetType']),
      amount: (json['amount'] as num).toDouble(),
      period: json['period'] as String? ?? 'monthly',
      categoryId: (json['categoryId'] as num?)?.toInt(),
      walletId: (json['walletId'] as num?)?.toInt(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$BudgetModelToJson(BudgetModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'budgetType': _$BudgetTypeEnumMap[instance.budgetType]!,
      'amount': instance.amount,
      'period': instance.period,
      'categoryId': instance.categoryId,
      'walletId': instance.walletId,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$BudgetTypeEnumMap = {
  BudgetType.limit: 'limit',
  BudgetType.target: 'target',
  BudgetType.expected: 'expected',
};
