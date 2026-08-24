import 'package:json_annotation/json_annotation.dart';

part 'transaction_model.g.dart';

@JsonEnum()
enum TransactionType {
  income,
  expense,
  transfer;

  static TransactionType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'transfer':
        return TransactionType.transfer;
      case 'expense':
      default:
        return TransactionType.expense;
    }
  }

  String toDbString() => name;
}

@JsonSerializable()
class TransactionModel {
  final int id;
  final int walletId;
  final int? categoryId;
  final double amount;
  final TransactionType transactionType;
  final String title;
  final String? description;
  final String? merchant;
  final String sourceInput; // 'manual' | 'text_parse' | 'ocr' | 'voice'
  final String? rawInput;
  final int? transferToWalletId;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Multi-currency: transaction currency + equivalent amount in IDR (base).
  final String currency;
  final double amountBase;

  // Joined presentation data (optional)
  final String? walletName;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  const TransactionModel({
    required this.id,
    required this.walletId,
    this.categoryId,
    required this.amount,
    required this.transactionType,
    required this.title,
    this.description,
    this.merchant,
    this.sourceInput = 'manual',
    this.rawInput,
    this.transferToWalletId,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.currency = 'IDR',
    this.amountBase = 0.0,
    this.walletName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => _$TransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

  factory TransactionModel.fromEntry(dynamic entry) {
    return TransactionModel(
      id: entry.id,
      walletId: entry.walletId,
      categoryId: entry.categoryId,
      amount: entry.amount,
      transactionType: TransactionType.fromString(entry.transactionType),
      title: entry.title,
      description: entry.description,
      merchant: entry.merchant,
      sourceInput: entry.sourceInput,
      rawInput: entry.rawInput,
      transferToWalletId: entry.transferToWalletId,
      transactionDate: entry.transactionDate,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      currency: entry.currency as String? ?? 'IDR',
      amountBase: (entry.amountBase as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get isIncome => transactionType == TransactionType.income;
  bool get isExpense => transactionType == TransactionType.expense;
  bool get isTransfer => transactionType == TransactionType.transfer;
}
