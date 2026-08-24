// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_rule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
