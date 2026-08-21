import '../../../core/utils/result.dart';
import 'smart_rule_model.dart';

abstract class SmartRuleRepositoryInterface {
  Stream<List<SmartRuleModel>> watchRules();
  Stream<List<SmartRuleModel>> watchActiveRules();
  Future<Result<List<SmartRuleModel>, AppError>> getActiveRules();
  Future<Result<SmartRuleModel, AppError>> getById(int id);
  Future<Result<int, AppError>> save(SmartRuleModel rule);
  Future<Result<bool, AppError>> delete(int id);
  Future<Result<bool, AppError>> toggle(int id, bool active);
}