import '../../features/transactions/domain/transaction_model.dart';

class ParsedTransaction {
  final double? amount;
  final String? categoryKey;
  final String? walletProvider; // 'gopay', 'ovo', 'dana', 'shopeepay', 'physical', etc.
  final TransactionType transactionType;
  final String title;
  final String? merchant; // Merchant/store name when extractable; feeds subscriptions & smart rules
  final double confidence; // 0.0 to 1.0
  final String rawInput;

  const ParsedTransaction({
    this.amount,
    this.categoryKey,
    this.walletProvider,
    this.transactionType = TransactionType.expense,
    required this.title,
    this.merchant,
    this.confidence = 0.0,
    required this.rawInput,
  });

  bool get hasAmount => amount != null && amount! > 0;
  bool get hasCategory => categoryKey != null;
  bool get hasWallet => walletProvider != null;

  ParsedTransaction copyWith({
    double? amount,
    String? categoryKey,
    String? walletProvider,
    TransactionType? transactionType,
    String? title,
    String? merchant,
    double? confidence,
    String? rawInput,
  }) {
    return ParsedTransaction(
      amount: amount ?? this.amount,
      categoryKey: categoryKey ?? this.categoryKey,
      walletProvider: walletProvider ?? this.walletProvider,
      transactionType: transactionType ?? this.transactionType,
      title: title ?? this.title,
      merchant: merchant ?? this.merchant,
      confidence: confidence ?? this.confidence,
      rawInput: rawInput ?? this.rawInput,
    );
  }
}
