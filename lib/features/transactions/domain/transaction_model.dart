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
    this.walletName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  bool get isIncome => transactionType == TransactionType.income;
  bool get isExpense => transactionType == TransactionType.expense;
  bool get isTransfer => transactionType == TransactionType.transfer;
}
