// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) =>
    TransactionModel(
      id: (json['id'] as num).toInt(),
      walletId: (json['walletId'] as num).toInt(),
      categoryId: (json['categoryId'] as num?)?.toInt(),
      amount: (json['amount'] as num).toDouble(),
      transactionType: $enumDecode(
        _$TransactionTypeEnumMap,
        json['transactionType'],
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      merchant: json['merchant'] as String?,
      sourceInput: json['sourceInput'] as String? ?? 'manual',
      rawInput: json['rawInput'] as String?,
      transferToWalletId: (json['transferToWalletId'] as num?)?.toInt(),
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      currency: json['currency'] as String? ?? 'IDR',
      amountBase: (json['amountBase'] as num?)?.toDouble() ?? 0.0,
      walletName: json['walletName'] as String?,
      categoryName: json['categoryName'] as String?,
      categoryIcon: json['categoryIcon'] as String?,
      categoryColor: json['categoryColor'] as String?,
    );

Map<String, dynamic> _$TransactionModelToJson(TransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'walletId': instance.walletId,
      'categoryId': instance.categoryId,
      'amount': instance.amount,
      'transactionType': _$TransactionTypeEnumMap[instance.transactionType]!,
      'title': instance.title,
      'description': instance.description,
      'merchant': instance.merchant,
      'sourceInput': instance.sourceInput,
      'rawInput': instance.rawInput,
      'transferToWalletId': instance.transferToWalletId,
      'transactionDate': instance.transactionDate.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'currency': instance.currency,
      'amountBase': instance.amountBase,
      'walletName': instance.walletName,
      'categoryName': instance.categoryName,
      'categoryIcon': instance.categoryIcon,
      'categoryColor': instance.categoryColor,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.income: 'income',
  TransactionType.expense: 'expense',
  TransactionType.transfer: 'transfer',
};
