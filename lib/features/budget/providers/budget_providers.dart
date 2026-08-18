import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../data/budget_repository.dart';
import '../domain/budget_model.dart';
import '../domain/budget_repository_interface.dart';

final budgetRepositoryProvider = Provider<BudgetRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return BudgetRepository(db);
});

final activeBudgetsProvider = StreamProvider.autoDispose<List<BudgetModel>>((ref) {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.watchActiveBudgets();
});

final primaryBudgetProvider = StreamProvider.autoDispose<BudgetModel?>((ref) {
  final budgetsAsync = ref.watch(activeBudgetsProvider);
  return budgetsAsync.when(
    data: (list) => Stream.value(list.isNotEmpty ? list.first : null),
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});
