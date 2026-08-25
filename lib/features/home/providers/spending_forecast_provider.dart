import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../services/llm/gemma_llm_service.dart';
import '../../budget/domain/budget_model.dart';
import '../../budget/domain/budget_period.dart';
import '../../budget/providers/budget_providers.dart';
import '../../categories/domain/category_model.dart';
import '../../categories/providers/category_providers.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../wallets/providers/wallet_providers.dart';
import '../domain/spending_forecast.dart';

/// Total expense within the active budget period (or current month when no
/// budget is set). Period-aware: aligns to the budget's [BudgetModel.startDate]
/// and [BudgetModel.period] so weekly/daily budgets forecast correctly instead
/// of always using the calendar month.
final periodExpenseProvider = StreamProvider.autoDispose<double>((ref) {
  final budgetAsync = ref.watch(primaryBudgetProvider);
  final bounds = computePeriodBounds(budgetAsync.value);
  final repo = ref.watch(transactionRepositoryProvider);

  return repo.watchByDateRange(bounds.start, DateTime.now()).map((list) {
    return list
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  });
});

/// Transactions that fall within the active budget period (or current month
/// when no budget is set). Used to derive the top spending category.
final periodTransactionsProvider = StreamProvider.autoDispose<List<TransactionModel>>((ref) {
  final budgetAsync = ref.watch(primaryBudgetProvider);
  final bounds = computePeriodBounds(budgetAsync.value);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchByDateRange(bounds.start, DateTime.now());
});

/// Projects the end-of-period balance and budget status from the live balance,
/// the active budget, and period transactions. Rebuilds whenever any source
/// changes (new transaction, budget edit, balance change).
final spendingForecastProvider = AsyncNotifierProvider.autoDispose<SpendingForecastNotifier, SpendingForecast>(
  SpendingForecastNotifier.new,
);

class SpendingForecastNotifier extends AsyncNotifier<SpendingForecast> {
  @override
  Future<SpendingForecast> build() async {
    final balance = await ref.watch(totalBalanceProvider.future);
    final budget = await ref.watch(primaryBudgetProvider.future);
    final categories = await ref.watch(allCategoriesProvider.future);
    final transactions = await ref.watch(periodTransactionsProvider.future);
    final spentSoFar = await ref.watch(periodExpenseProvider.future);

    return _computeForecast(
      balance: balance,
      budget: budget,
      categories: categories,
      transactions: transactions,
      spentSoFar: spentSoFar,
    );
  }
}

/// Thin Gemma layer: if the on-device model is downloaded, ask it to rephrase
/// the precomputed facts into one friendly sentence (it must NOT recompute
/// numbers). Falls back to `null` (the widget then uses the rule-based
/// template) when the model is unavailable or the call fails.
///
/// The [locale] argument (e.g. 'en' / 'id') selects the response language.
final aiSpendingAdviceProvider = FutureProvider.autoDispose.family<String?, String>((ref, locale) async {
  final forecastAsync = ref.watch(spendingForecastProvider);
  final forecast = forecastAsync.value;
  if (forecast == null || forecast.topCategory == null) return null;

  final gemma = ref.watch(gemmaLlmServiceProvider);
  final downloaded = await gemma.isModelDownloaded();
  if (!downloaded) return null;

  final prompt = _buildAdvicePrompt(forecast, locale);
  final result = await gemma.generateResponse(userPrompt: prompt);
  if (result.isSuccess) {
    final text = result.valueOrNull?.trim() ?? '';
    if (text.isNotEmpty && !text.startsWith('__TOOL__')) {
      return text;
    }
  }
  return null;
});

SpendingForecast _computeForecast({
  required double balance,
  required BudgetModel? budget,
  required List<CategoryModel> categories,
  required List<TransactionModel> transactions,
  required double spentSoFar,
}) {
  final bounds = computePeriodBounds(budget);

  final categoryNameById = {
    for (final c in categories) c.id: c.name,
  };

  final expenses = transactions.where((t) => t.isExpense).toList();

  final Map<String, double> byCategory = {};
  for (final tx in expenses) {
    final name = tx.categoryId != null ? categoryNameById[tx.categoryId] : null;
    final key = name ?? 'other';
    byCategory[key] = (byCategory[key] ?? 0) + tx.amount;
  }

  String? topCategory;
  double topCategoryAmount = 0;
  byCategory.forEach((name, amount) {
    if (amount > topCategoryAmount) {
      topCategoryAmount = amount;
      topCategory = name;
    }
  });

  return computeForecast(
    balance: balance,
    budgetLimit: budget?.amount,
    spentSoFar: spentSoFar,
    daysElapsed: bounds.daysElapsed,
    daysInPeriod: bounds.daysInPeriod,
    topCategory: topCategory,
    topCategoryAmount: topCategoryAmount,
  );
}

String _buildAdvicePrompt(SpendingForecast f, String locale) {
  final balance = RupiahFormatter.format(f.projectedBalance);
  final spend = RupiahFormatter.format(f.forecastSpend);
  final top = f.topCategory ?? '-';
  final topAmt = RupiahFormatter.format(f.topCategoryAmount);
  final status = f.willBustBudget
      ? (locale == 'id' ? 'akan melebihi batas anggaran' : 'will exceed the budget')
      : (locale == 'id' ? 'masih aman dalam anggaran' : 'is still within budget');

  if (locale == 'id') {
    return '''
Fakta keuangan pengguna (JANGAN hitung ulang angka, gunakan apa adanya):
- Proyeksi saldo akhir periode: $balance
- Proyeksi total pengeluaran: $spend
- Status anggaran: $status
- Kategori pengeluaran terbesar: $top sebesar $topAmt
Tulis SATU kalimat singkat, ramah, dan suportif dalam bahasa Indonesia (maksimal 25 kata) yang merangkai fakta di atas menjadi saran. Jangan sebutkan angka selain yang sudah diberikan.
''';
  }
  return '''
User's financial facts (do NOT recompute the numbers, use them as given):
- Projected end-of-period balance: $balance
- Projected total spending: $spend
- Budget status: $status
- Top spending category: $top at $topAmt
Write ONE short, friendly, supportive sentence in English (max 25 words) that weaves these facts into advice. Do not introduce numbers other than those given.
''';
}
