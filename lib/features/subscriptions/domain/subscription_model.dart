import 'package:json_annotation/json_annotation.dart';

part 'subscription_model.g.dart';

@JsonSerializable()
class SubscriptionModel {
  final int id;
  final String merchant;
  final String normalizedKey;
  final double amount;
  final String period;
  final int? categoryId;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final int occurrenceCount;
  final double confidence;
  final bool isActive;
  final bool isConfirmed;
  final DateTime createdAt;

  const SubscriptionModel({
    required this.id,
    required this.merchant,
    required this.normalizedKey,
    required this.amount,
    required this.period,
    this.categoryId,
    required this.firstSeen,
    required this.lastSeen,
    required this.occurrenceCount,
    required this.confidence,
    required this.isActive,
    required this.isConfirmed,
    required this.createdAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) => _$SubscriptionModelFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionModelToJson(this);

  DateTime get nextChargeEstimate => lastSeen.add(const Duration(days: 30));

  SubscriptionModel copyWith({
    int? id,
    String? merchant,
    String? normalizedKey,
    double? amount,
    String? period,
    int? categoryId,
    DateTime? firstSeen,
    DateTime? lastSeen,
    int? occurrenceCount,
    double? confidence,
    bool? isActive,
    bool? isConfirmed,
    DateTime? createdAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      normalizedKey: normalizedKey ?? this.normalizedKey,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      categoryId: categoryId ?? this.categoryId,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      confidence: confidence ?? this.confidence,
      isActive: isActive ?? this.isActive,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}