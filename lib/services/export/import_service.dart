import 'dart:convert';
import '../../core/utils/result.dart';
import '../../features/transactions/domain/transaction_model.dart';
import 'export_model.dart';

class ImportService {
  const ImportService();

  Future<Result<ExportBundle, AppError>> parseJson(String jsonString) async {
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      // Validate required fields
      if (!jsonMap.containsKey('wallets') ||
          !jsonMap.containsKey('categories') ||
          !jsonMap.containsKey('transactions') ||
          !jsonMap.containsKey('budgets') ||
          !jsonMap.containsKey('smartRules')) {
        return Failure(AppError.parse('Invalid JSON format: missing required fields'));
      }

      final bundle = ExportBundle.fromJson(jsonMap);

      // Validate data integrity
      final validationError = _validateBundle(bundle);
      if (validationError != null) {
        return Failure(AppError.validation(validationError));
      }

      return Success(bundle);
    } on FormatException catch (e) {
      return Failure(AppError.parse('Invalid JSON format: ${e.message}'));
    } catch (e) {
      return Failure(AppError.parse('Failed to parse JSON: $e'));
    }
  }

  Future<Result<ExportBundle, AppError>> parseCsv(String csvString) async {
    try {
      final lines = csvString.trim().split('\n');
      if (lines.isEmpty) {
        return Failure(AppError.parse('Empty CSV'));
      }

      // Parse header
      final header = _parseCsvLine(lines.first);
      final expectedHeaders = [
        'id',
        'walletId',
        'categoryId',
        'amount',
        'type',
        'title',
        'date',
      ];

      // Check if required headers exist
      for (final expected in expectedHeaders) {
        if (!header.contains(expected)) {
          return Failure(AppError.parse('CSV missing required column: $expected'));
        }
      }

      final transactions = <TransactionModel>[];
      final warnings = <String>[];

      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final fields = _parseCsvLine(line);
        if (fields.length < expectedHeaders.length) {
          warnings.add('Row $i: insufficient columns, skipping');
          continue;
        }

        final rowMap = <String, String>{};
        for (var j = 0; j < header.length && j < fields.length; j++) {
          rowMap[header[j]] = fields[j];
        }

        final txResult = _parseTransactionRow(rowMap, i);
        if (txResult.isSuccess) {
          transactions.add(txResult.valueOrNull!);
        } else {
          warnings.add('Row $i: ${txResult.errorOrNull?.message ?? 'Unknown error'}');
        }
      }

      // Create a minimal bundle with only transactions (CSV only supports transactions)
      final bundle = ExportBundle(
        wallets: [],
        categories: [],
        transactions: transactions,
        budgets: [],
        smartRules: [],
        exportedAt: DateTime.now(),
      );

      return Success(bundle);
    } catch (e) {
      return Failure(AppError.parse('Failed to parse CSV: $e'));
    }
  }

  List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++; // Skip next quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    fields.add(buffer.toString());
    return fields;
  }

  Result<TransactionModel, AppError> _parseTransactionRow(
    Map<String, String> row,
    int rowNumber,
  ) {
    try {
      final id = int.tryParse(row['id'] ?? '');
      final walletId = int.tryParse(row['walletId'] ?? '');
      final categoryIdStr = row['categoryId'] ?? '';
      final categoryId = categoryIdStr.isNotEmpty ? int.tryParse(categoryIdStr) : null;
      final amount = double.tryParse(row['amount'] ?? '');
      final typeStr = row['type'] ?? '';
      final title = row['title'] ?? '';
      final dateStr = row['date'] ?? '';

      if (id == null) {
        return Failure(AppError.validation('Row $rowNumber: invalid id'));
      }
      if (walletId == null) {
        return Failure(AppError.validation('Row $rowNumber: invalid walletId'));
      }
      if (amount == null || amount <= 0) {
        return Failure(AppError.validation('Row $rowNumber: amount must be > 0'));
      }
      if (title.isEmpty) {
        return Failure(AppError.validation('Row $rowNumber: title is required'));
      }

      final transactionType = TransactionType.fromString(typeStr);
      final transactionDate = DateTime.tryParse(dateStr) ?? DateTime.now();

      final description = row['description'];
      final merchant = row['merchant'];
      final sourceInput = row['sourceInput'] ?? 'manual';
      final rawInput = row['rawInput'];
      final transferToWalletIdStr = row['transferToWalletId'] ?? '';
      final transferToWalletId =
          transferToWalletIdStr.isNotEmpty ? int.tryParse(transferToWalletIdStr) : null;
      final createdAt = DateTime.tryParse(row['createdAt'] ?? '') ?? DateTime.now();
      final updatedAt = DateTime.tryParse(row['updatedAt'] ?? '') ?? DateTime.now();

      return Success(TransactionModel(
        id: id,
        walletId: walletId,
        categoryId: categoryId,
        amount: amount,
        transactionType: transactionType,
        title: title,
        description: description?.isEmpty == true ? null : description,
        merchant: merchant?.isEmpty == true ? null : merchant,
        sourceInput: sourceInput,
        rawInput: rawInput?.isEmpty == true ? null : rawInput,
        transferToWalletId: transferToWalletId,
        transactionDate: transactionDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ));
    } catch (e) {
      return Failure(AppError.parse('Row $rowNumber: $e'));
    }
  }

  String? _validateBundle(ExportBundle bundle) {
    // Validate wallets
    final walletIds = <int>{};
    for (final wallet in bundle.wallets) {
      if (wallet.id <= 0) return 'Wallet id must be > 0';
      if (!walletIds.add(wallet.id)) return 'Duplicate wallet id: ${wallet.id}';
      if (wallet.balance < 0) return 'Wallet balance cannot be negative';
    }

    // Validate categories
    final categoryIds = <int>{};
    final categoryKeys = <String>{};
    for (final cat in bundle.categories) {
      if (cat.id <= 0) return 'Category id must be > 0';
      if (!categoryIds.add(cat.id)) return 'Duplicate category id: ${cat.id}';
      if (!categoryKeys.add(cat.key)) return 'Duplicate category key: ${cat.key}';
    }

    // Validate transactions
    for (final tx in bundle.transactions) {
      if (tx.id <= 0) return 'Transaction id must be > 0';
      if (tx.amount <= 0) return 'Transaction amount must be > 0';
      if (tx.title.isEmpty) return 'Transaction title is required';
      if (!walletIds.contains(tx.walletId)) {
        return 'Transaction references non-existent wallet: ${tx.walletId}';
      }
      if (tx.categoryId != null && !categoryIds.contains(tx.categoryId!)) {
        return 'Transaction references non-existent category: ${tx.categoryId}';
      }
      if (tx.transferToWalletId != null && !walletIds.contains(tx.transferToWalletId!)) {
        return 'Transaction references non-existent transfer wallet: ${tx.transferToWalletId}';
      }
    }

    // Validate budgets
    for (final budget in bundle.budgets) {
      if (budget.id <= 0) return 'Budget id must be > 0';
      if (budget.amount <= 0) return 'Budget amount must be > 0';
      if (budget.categoryId != null && !categoryIds.contains(budget.categoryId!)) {
        return 'Budget references non-existent category: ${budget.categoryId}';
      }
      if (budget.walletId != null && !walletIds.contains(budget.walletId!)) {
        return 'Budget references non-existent wallet: ${budget.walletId}';
      }
    }

    // Validate smart rules
    for (final rule in bundle.smartRules) {
      if (rule.id <= 0) return 'Smart rule id must be > 0';
      if (rule.name.isEmpty) return 'Smart rule name is required';
    }

    return null;
  }
}