import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction_model.dart';
import '../domain/transaction_repository_interface.dart';
import '../../categories/providers/category_providers.dart';
import '../../wallets/providers/wallet_providers.dart';

final transactionRepositoryProvider = Provider<TransactionRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return TransactionRepository(db);
});

final recentTransactionsProvider = StreamProvider.autoDispose<List<TransactionModel>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  final categoriesAsync = ref.watch(allCategoriesProvider);
  final walletsAsync = ref.watch(allWalletsProvider);

  return repo.watchRecent(limit: 20).map((transactions) {
    final categories = categoriesAsync.asData?.value ?? [];
    final wallets = walletsAsync.asData?.value ?? [];

    final categoryMap = {for (final c in categories) c.id: c};
    final walletMap = {for (final w in wallets) w.id: w};

    return transactions.map((tx) {
      final category = tx.categoryId != null ? categoryMap[tx.categoryId] : null;
      final wallet = walletMap[tx.walletId];

      return TransactionModel(
        id: tx.id,
        walletId: tx.walletId,
        categoryId: tx.categoryId,
        amount: tx.amount,
        transactionType: tx.transactionType,
        title: tx.title,
        description: tx.description,
        merchant: tx.merchant,
        sourceInput: tx.sourceInput,
        rawInput: tx.rawInput,
        transferToWalletId: tx.transferToWalletId,
        transactionDate: tx.transactionDate,
        createdAt: tx.createdAt,
        updatedAt: tx.updatedAt,
        walletName: wallet?.name,
        categoryName: category?.name,
        categoryIcon: category?.icon,
        categoryColor: category?.color,
      );
    }).toList();
  });
});

final currentMonthIncomeProvider = StreamProvider.autoDispose<double>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchTotalIncomeForMonth(DateTime.now());
});

final currentMonthExpenseProvider = StreamProvider.autoDispose<double>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchTotalExpenseForMonth(DateTime.now());
});
