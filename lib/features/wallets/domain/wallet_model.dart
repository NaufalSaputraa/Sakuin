import 'package:json_annotation/json_annotation.dart';

part 'wallet_model.g.dart';

@JsonSerializable()
class WalletModel {
  final int id;
  final String name;
  final String walletType; // 'physical' | 'digital'
  final int? parentId;
  final String? provider; // 'gopay', 'ovo', 'dana', 'shopeepay', 'bank'
  final double balance;
  final String currency;
  final String? icon;
  final String? color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletModel({
    required this.id,
    required this.name,
    required this.walletType,
    this.parentId,
    this.provider,
    required this.balance,
    this.currency = 'IDR',
    this.icon,
    this.color,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => _$WalletModelFromJson(json);

  Map<String, dynamic> toJson() => _$WalletModelToJson(this);

  bool get isSubWallet => parentId != null;
  bool get isPhysical => walletType == 'physical';
  bool get isDigital => walletType == 'digital';

  WalletModel copyWith({
    int? id,
    String? name,
    String? walletType,
    int? parentId,
    String? provider,
    double? balance,
    String? currency,
    String? icon,
    String? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      walletType: walletType ?? this.walletType,
      parentId: parentId ?? this.parentId,
      provider: provider ?? this.provider,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
