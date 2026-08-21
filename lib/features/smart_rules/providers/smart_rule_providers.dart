import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../services/ml/smart_rule_evaluator_service.dart';
import '../../../services/ml/smart_rule_learning_service.dart';
import '../data/smart_rule_repository.dart';
import '../domain/smart_rule_model.dart';
import '../domain/smart_rule_repository_interface.dart';

final smartRuleRepositoryProvider = Provider<SmartRuleRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return SmartRuleRepository(db);
});

final smartRuleEvaluatorServiceProvider = Provider<SmartRuleEvaluatorService>((ref) {
  final repo = ref.watch(smartRuleRepositoryProvider);
  return SmartRuleEvaluatorService(repo);
});

final smartRuleLearningServiceProvider = Provider<SmartRuleLearningService>((ref) {
  final db = ref.watch(databaseProvider);
  final repo = ref.watch(smartRuleRepositoryProvider);
  return SmartRuleLearningService(db, repo);
});

final smartRulesProvider = StreamProvider.autoDispose<List<SmartRuleModel>>((ref) {
  final repo = ref.watch(smartRuleRepositoryProvider);
  return repo.watchRules();
});

final activeSmartRulesProvider = StreamProvider.autoDispose<List<SmartRuleModel>>((ref) {
  final repo = ref.watch(smartRuleRepositoryProvider);
  return repo.watchActiveRules();
});

class SmartRulesNotifier extends Notifier<AsyncValue<List<SmartRuleModel>>> {
  @override
  AsyncValue<List<SmartRuleModel>> build() {
    return const AsyncValue.loading();
  }

  Future<void> loadRules() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(smartRuleRepositoryProvider);
      final result = await repo.getActiveRules();
      state = result.when(
        success: (rules) => AsyncValue.data(rules),
        failure: (error) => AsyncValue.error(error, StackTrace.current),
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addRule(SmartRuleModel rule) async {
    final repo = ref.read(smartRuleRepositoryProvider);
    final result = await repo.save(rule);
    if (result.isSuccess) {
      await loadRules();
    } else {
      throw result.errorOrNull!;
    }
  }

  Future<void> updateRule(SmartRuleModel rule) async {
    final repo = ref.read(smartRuleRepositoryProvider);
    final result = await repo.save(rule);
    if (result.isSuccess) {
      await loadRules();
    } else {
      throw result.errorOrNull!;
    }
  }

  Future<void> deleteRule(int id) async {
    final repo = ref.read(smartRuleRepositoryProvider);
    final result = await repo.delete(id);
    if (result.isSuccess) {
      await loadRules();
    } else {
      throw result.errorOrNull!;
    }
  }

  Future<void> toggleRule(int id, bool active) async {
    final repo = ref.read(smartRuleRepositoryProvider);
    final result = await repo.toggle(id, active);
    if (result.isSuccess) {
      await loadRules();
    } else {
      throw result.errorOrNull!;
    }
  }
}

final smartRulesNotifierProvider = NotifierProvider<SmartRulesNotifier, AsyncValue<List<SmartRuleModel>>>(
  SmartRulesNotifier.new,
);

final smartRuleEvaluationProvider = FutureProvider.autoDispose.family<
    RuleEvaluationResult,
    ({
      String merchant,
      String title,
      double amount,
      int? categoryId,
    })
>((ref, params) async {
  final evaluator = ref.watch(smartRuleEvaluatorServiceProvider);
  return evaluator.evaluate(
    merchant: params.merchant,
    title: params.title,
    amount: params.amount,
    categoryId: params.categoryId,
  );
});