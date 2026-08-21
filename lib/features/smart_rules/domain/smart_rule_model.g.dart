// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_rule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RuleCondition _$RuleConditionFromJson(Map<String, dynamic> json) =>
    RuleCondition(
      field: $enumDecode(_$RuleFieldEnumMap, json['field']),
      operator: $enumDecode(_$RuleOperatorEnumMap, json['operator']),
      value: json['value'] as String,
    );

Map<String, dynamic> _$RuleConditionToJson(RuleCondition instance) =>
    <String, dynamic>{
      'field': _$RuleFieldEnumMap[instance.field]!,
      'operator': _$RuleOperatorEnumMap[instance.operator]!,
      'value': instance.value,
    };

const _$RuleFieldEnumMap = {
  RuleField.merchant: 'merchant',
  RuleField.title: 'title',
  RuleField.amount: 'amount',
  RuleField.categoryId: 'categoryId',
};

const _$RuleOperatorEnumMap = {
  RuleOperator.contains: 'contains',
  RuleOperator.equals: 'equals',
  RuleOperator.gt: 'gt',
  RuleOperator.lt: 'lt',
  RuleOperator.gte: 'gte',
  RuleOperator.lte: 'lte',
};

RuleAction _$RuleActionFromJson(Map<String, dynamic> json) => RuleAction(
      type: $enumDecode(_$RuleActionTypeEnumMap, json['type']),
      value: json['value'] as String,
    );

Map<String, dynamic> _$RuleActionToJson(RuleAction instance) =>
    <String, dynamic>{
      'type': _$RuleActionTypeEnumMap[instance.type]!,
      'value': instance.value,
    };

const _$RuleActionTypeEnumMap = {
  RuleActionType.categorize: 'categorize',
  RuleActionType.tag: 'tag',
  RuleActionType.wallet: 'wallet',
};

SmartRuleModel _$SmartRuleModelFromJson(Map<String, dynamic> json) =>
    SmartRuleModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      isActive: json['isActive'] as bool,
      conditions: (json['conditions'] as List<dynamic>)
          .map((e) => RuleCondition.fromJson(e as Map<String, dynamic>))
          .toList(),
      action: RuleAction.fromJson(json['action'] as Map<String, dynamic>),
      priority: (json['priority'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SmartRuleModelToJson(SmartRuleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isActive': instance.isActive,
      'conditions': instance.conditions,
      'action': instance.action,
      'priority': instance.priority,
      'createdAt': instance.createdAt.toIso8601String(),
    };
