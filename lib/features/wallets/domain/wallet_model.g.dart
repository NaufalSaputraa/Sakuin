// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletModel _$WalletModelFromJson(Map<String, dynamic> json) => WalletModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  walletType: json['walletType'] as String,
  parentId: (json['parentId'] as num?)?.toInt(),
  provider: json['provider'] as String?,
  balance: (json['balance'] as num).toDouble(),
  currency: json['currency'] as String? ?? 'IDR',
  icon: json['icon'] as String?,
  color: json['color'] as String?,
  isActive: json['isActive'] as bool? ?? true,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$WalletModelToJson(WalletModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'walletType': instance.walletType,
      'parentId': instance.parentId,
      'provider': instance.provider,
      'balance': instance.balance,
      'currency': instance.currency,
      'icon': instance.icon,
      'color': instance.color,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
