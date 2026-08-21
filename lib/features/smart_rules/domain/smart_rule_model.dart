import 'package:json_annotation/json_annotation.dart';

part 'smart_rule_model.g.dart';

@JsonEnum()
enum RuleField {
  merchant,
  title,
  amount,
  categoryId;

  static RuleField fromString(String val) {
    switch (val.toLowerCase()) {
      case 'merchant':
        return RuleField.merchant;
      case 'title':
        return RuleField.title;
      case 'amount':
        return RuleField.amount;
      case 'categoryid':
      case 'category_id':
        return RuleField.categoryId;
      default:
        return RuleField.merchant;
    }
  }

  String toDbString() => name;
}

@JsonEnum()
enum RuleOperator {
  contains,
  equals,
  gt,
  lt,
  gte,
  lte;

  static RuleOperator fromString(String val) {
    switch (val.toLowerCase()) {
      case 'contains':
        return RuleOperator.contains;
      case 'equals':
        return RuleOperator.equals;
      case 'gt':
      case '>':
        return RuleOperator.gt;
      case 'lt':
      case '<':
        return RuleOperator.lt;
      case 'gte':
      case '>=':
        return RuleOperator.gte;
      case 'lte':
      case '<=':
        return RuleOperator.lte;
      default:
        return RuleOperator.contains;
    }
  }

  String toDbString() => name;
}

@JsonEnum()
enum RuleActionType {
  categorize,
  tag,
  wallet;

  static RuleActionType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'categorize':
        return RuleActionType.categorize;
      case 'tag':
        return RuleActionType.tag;
      case 'wallet':
        return RuleActionType.wallet;
      default:
        return RuleActionType.categorize;
    }
  }

  String toDbString() => name;
}

@JsonSerializable()
class RuleCondition {
  final RuleField field;
  final RuleOperator operator;
  final String value;

  const RuleCondition({
    required this.field,
    required this.operator,
    required this.value,
  });

  factory RuleCondition.fromJson(Map<String, dynamic> json) {
    return RuleCondition(
      field: RuleField.fromString(json['field'] as String? ?? 'merchant'),
      operator: RuleOperator.fromString(json['operator'] as String? ?? 'contains'),
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field.toDbString(),
      'operator': operator.toDbString(),
      'value': value,
    };
  }

  RuleCondition copyWith({
    RuleField? field,
    RuleOperator? operator,
    String? value,
  }) {
    return RuleCondition(
      field: field ?? this.field,
      operator: operator ?? this.operator,
      value: value ?? this.value,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuleCondition &&
          runtimeType == other.runtimeType &&
          field == other.field &&
          operator == other.operator &&
          value == other.value;

  @override
  int get hashCode => Object.hash(field, operator, value);

  @override
  String toString() => 'RuleCondition(field: $field, operator: $operator, value: $value)';
}

@JsonSerializable()
class RuleAction {
  final RuleActionType type;
  final String value; // JSON string for structured data

  const RuleAction({
    required this.type,
    required this.value,
  });

  factory RuleAction.fromJson(Map<String, dynamic> json) {
    return RuleAction(
      type: RuleActionType.fromString(json['type'] as String? ?? 'categorize'),
      value: json['value'] as String? ?? '{}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toDbString(),
      'value': value,
    };
  }

  RuleAction copyWith({
    RuleActionType? type,
    String? value,
  }) {
    return RuleAction(
      type: type ?? this.type,
      value: value ?? this.value,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuleAction &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          value == other.value;

  @override
  int get hashCode => Object.hash(type, value);

  @override
  String toString() => 'RuleAction(type: $type, value: $value)';
}

@JsonSerializable()
class SmartRuleModel {
  final int id;
  final String name;
  final bool isActive;
  final List<RuleCondition> conditions;
  final RuleAction action;
  final int priority;
  final DateTime createdAt;

  const SmartRuleModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.conditions,
    required this.action,
    required this.priority,
    required this.createdAt,
  });

  factory SmartRuleModel.fromJson(Map<String, dynamic> json) => _$SmartRuleModelFromJson(json);

  Map<String, dynamic> toJson() => _$SmartRuleModelToJson(this);

  SmartRuleModel copyWith({
    int? id,
    String? name,
    bool? isActive,
    List<RuleCondition>? conditions,
    RuleAction? action,
    int? priority,
    DateTime? createdAt,
  }) {
    return SmartRuleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      conditions: conditions ?? this.conditions,
      action: action ?? this.action,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartRuleModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          isActive == other.isActive &&
          conditions == other.conditions &&
          action == other.action &&
          priority == other.priority &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      Object.hash(id, name, isActive, conditions, action, priority, createdAt);

  @override
  String toString() =>
      'SmartRuleModel(id: $id, name: $name, isActive: $isActive, conditions: $conditions, action: $action, priority: $priority)';
}