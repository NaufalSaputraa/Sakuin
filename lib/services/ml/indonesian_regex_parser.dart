import '../../core/utils/currency_formatter.dart';
import '../../features/transactions/domain/transaction_model.dart';
import 'parsed_transaction.dart';

class IndonesianRegexParser {
  // Action verbs for Income
  static final RegExp _incomeVerbs = RegExp(
    r'\b(gaji|pendapatan|dapat|terima|dapet|cair|tf\s+masuk|transfer\s+masuk|bonus|thr|hasil|freelance)\b',
    caseSensitive: false,
  );

  // Action verbs for Transfer
  static final RegExp _transferVerbs = RegExp(
    r'\b(tf|transfer|tarik\s+tunai|tarik|kirim\s+uang|topup|top\s+up|isi\s+saldo)\b',
    caseSensitive: false,
  );

  // E-Wallet & Bank keywords
  static final Map<String, RegExp> _walletKeywords = {
    'gopay': RegExp(r'\b(gopay|go-pay|gojek)\b', caseSensitive: false),
    'ovo': RegExp(r'\b(ovo|grab)\b', caseSensitive: false),
    'dana': RegExp(r'\b(dana)\b', caseSensitive: false),
    'shopeepay': RegExp(r'\b(shopeepay|shopee-pay|shopee)\b', caseSensitive: false),
    'physical': RegExp(r'\b(cash|tunai|uang\s+fisik|dompet)\b', caseSensitive: false),
    'bank': RegExp(r'\b(bca|mandiri|bri|bni|bsi|jago|jenius|rekening|bank)\b', caseSensitive: false),
  };

  // Category keyword mappings
  static final Map<String, RegExp> _categoryKeywords = {
    'food': RegExp(
      r'\b(makan|minum|kopi|coffee|lunch|dinner|sarapan|bakso|mie|nasi|ayam|gorengan|martabak|sate|mcd|kfc|starbucks|chatime|haus|indomaret|alfamart|snack|jajan)\b',
      caseSensitive: false,
    ),
    'transport': RegExp(
      r'\b(ojol|gojek|grab|maxim|inドライブ|taxi|taksi|kereta|krl|mrt|lrt|bus|busway|transjakarta|tol|parkir|angkot)\b',
      caseSensitive: false,
    ),
    'fuel': RegExp(
      r'\b(bensin|bbm|pertamax|pertalite|solar|spbu|shell|bp)\b',
      caseSensitive: false,
    ),
    'pulsa': RegExp(
      r'\b(pulsa|kuota|paket\s+data|telkomsel|indosat|xl|tri|smartfren|byu)\b',
      caseSensitive: false,
    ),
    'bills': RegExp(
      r'\b(listrik|pln|token|air|pdam|wifi|indihome|biznet|iuran|bpjs|pajak)\b',
      caseSensitive: false,
    ),
    'housing': RegExp(
      r'\b(kos|kost|kontrakan|sewa|apartemen|ipl)\b',
      caseSensitive: false,
    ),
    'shopping': RegExp(
      r'\b(belanja|baju|sepatu|tokopedia|shopee|lazada|mall|tiktok\s+shop)\b',
      caseSensitive: false,
    ),
    'health': RegExp(
      r'\b(obat|apotek|dokter|klinik|rumah\s+sakit|rs|vitamin|periksa)\b',
      caseSensitive: false,
    ),
    'entertainment': RegExp(
      r'\b(bioskop|nonton|cinema|xxi|game|steam|topup\s+game|netflix|spotify|youtube)\b',
      caseSensitive: false,
    ),
    'salary': RegExp(
      r'\b(gaji|payroll|upah|honor|salary)\b',
      caseSensitive: false,
    ),
    'freelance': RegExp(
      r'\b(freelance|proyek|klien|side\s+job|honorarium)\b',
      caseSensitive: false,
    ),
  };

  static ParsedTransaction parse(String text) {
    final clean = text.trim();
    if (clean.isEmpty) {
      return ParsedTransaction(title: 'Transaksi', rawInput: clean);
    }

    // 1. Extract Amount
    final amount = IndonesianAmountParser.parse(clean);

    // 2. Determine Transaction Type
    var type = TransactionType.expense;
    if (_incomeVerbs.hasMatch(clean)) {
      type = TransactionType.income;
    } else if (_transferVerbs.hasMatch(clean) && !clean.toLowerCase().contains('beli')) {
      type = TransactionType.transfer;
    }

    // 3. Detect Wallet
    String? matchedWallet;
    for (final entry in _walletKeywords.entries) {
      if (entry.value.hasMatch(clean)) {
        matchedWallet = entry.key;
        break;
      }
    }

    // 4. Detect Category
    String? matchedCategory;
    for (final entry in _categoryKeywords.entries) {
      if (entry.value.hasMatch(clean)) {
        matchedCategory = entry.key;
        break;
      }
    }

    if (type == TransactionType.income && matchedCategory == null) {
      matchedCategory = 'other_income';
    }

    // 5. Generate Title (cleanup verbs and amounts to get subject)
    var title = clean;
    // Remove amount string
    title = title.replaceAll(RegExp(r'(?:rp\.?\s*)?[0-9.,]+\s*(k|rb|ribu|jt|juta|m|miliar|b)?', caseSensitive: false), '');
    // Remove common prepositions and wallet names
    title = title.replaceAll(RegExp(r'\b(beli|bayar|isi|buat|untuk|pake|pakai|via|dari|ke|gopay|ovo|dana|shopeepay|cash|bca)\b', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (title.isEmpty) {
      if (matchedCategory != null) {
        title = matchedCategory[0].toUpperCase() + matchedCategory.substring(1);
      } else {
        title = type == TransactionType.income ? 'Pemasukan' : 'Pengeluaran';
      }
    } else {
      // Capitalize first letter
      title = title[0].toUpperCase() + title.substring(1);
    }

    double confidence = 0.4;
    if (amount != null) confidence += 0.3;
    if (matchedCategory != null) confidence += 0.2;
    if (matchedWallet != null) confidence += 0.1;

    return ParsedTransaction(
      amount: amount,
      categoryKey: matchedCategory,
      walletProvider: matchedWallet,
      transactionType: type,
      title: title,
      confidence: confidence.clamp(0.0, 1.0),
      rawInput: clean,
    );
  }
}
