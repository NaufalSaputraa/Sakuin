// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionModel _$SubscriptionModelFromJson(Map<String, dynamic> json) =>
    SubscriptionModel(
      id: (json['id'] as num).toInt(),
      merchant: json['merchant'] as String,
      normalizedKey: json['normalizedKey'] as String,
      amount: (json['amount'] as num).toDouble(),
      period: json['period'] as String,
      categoryId: (json['categoryId'] as num?)?.toInt(),
      firstSeen: DateTime.parse(json['firstSeen'] as String),
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      occurrenceCount: (json['occurrenceCount'] as num).toInt(),
      confidence: (json['confidence'] as num).toDouble(),
      isActive: json['isActive'] as bool,
      isConfirmed: json['isConfirmed'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SubscriptionModelToJson(SubscriptionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'merchant': instance.merchant,
      'normalizedKey': instance.normalizedKey,
      'amount': instance.amount,
      'period': instance.period,
      'categoryId': instance.categoryId,
      'firstSeen': instance.firstSeen.toIso8601String(),
      'lastSeen': instance.lastSeen.toIso8601String(),
      'occurrenceCount': instance.occurrenceCount,
      'confidence': instance.confidence,
      'isActive': instance.isActive,
      'isConfirmed': instance.isConfirmed,
      'createdAt': instance.createdAt.toIso8601String(),
    };
