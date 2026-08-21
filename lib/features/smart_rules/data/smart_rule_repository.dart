import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/result.dart';
import '../domain/smart_rule_model.dart';
import '../domain/smart_rule_repository_interface.dart';

class SmartRuleRepository implements SmartRuleRepositoryInterface {
  final AppDatabase _db;

  SmartRuleRepository(this._db);

  SmartRuleModel _toDomain(SmartRuleEntry entry) {
    final conditionsJson = jsonDecode(entry.conditions) as List<dynamic>;
    final actionJson = jsonDecode(entry.actionValue) as Map<String, dynamic>;

    return SmartRuleModel(
      id: entry.id,
      name: entry.name,
      isActive: entry.isActive,
      conditions: conditionsJson
          .map((e) => RuleCondition.fromJson(e as Map<String, dynamic>))
          .toList(),
      action: RuleAction.fromJson(actionJson),
      priority: entry.priority,
      createdAt: entry.createdAt,
    );
  }

  SmartRulesCompanion _toCompanion(SmartRuleModel rule) {
    return SmartRulesCompanion.insert(
      name: rule.name,
      isActive: Value(rule.isActive),
      conditions: jsonEncode(rule.conditions.map((c) => c.toJson()).toList()),
      actionType: rule.action.type.toDbString(),
      actionValue: rule.action.value,
      priority: Value(rule.priority),
    );
  }

  @override
  Stream<List<SmartRuleModel>> watchRules() {
    return _db.smartRuleDao.watchAll().map((list) => list.map(_toDomain).toList());
  }

  @override
  Stream<List<SmartRuleModel>> watchActiveRules() {
    return _db.smartRuleDao.watchActive().map((list) => list.map(_toDomain).toList());
  }

  @override
  Future<Result<List<SmartRuleModel>, AppError>> getActiveRules() async {
    try {
      final list = await _db.smartRuleDao.getActive();
      return Success(list.map(_toDomain).toList());
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  @override
  Future<Result<SmartRuleModel, AppError>> getById(int id) async {
    try {
      final item = await _db.smartRuleDao.getById(id);
      if (item == null) {
        return Failure(AppError.notFound('Smart rule not found'));
      }
      return Success(_toDomain(item));
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  @override
  Future<Result<int, AppError>> save(SmartRuleModel rule) async {
    try {
      if (rule.id == 0) {
        final id = await _db.smartRuleDao.insertRule(_toCompanion(rule));
        return Success(id);
      } else {
        final entry = SmartRuleEntry(
          id: rule.id,
          name: rule.name,
          isActive: rule.isActive,
          conditions: jsonEncode(rule.conditions.map((c) => c.toJson()).toList()),
          actionType: rule.action.type.toDbString(),
          actionValue: rule.action.value,
          priority: rule.priority,
          createdAt: rule.createdAt,
        );
        await _db.smartRuleDao.updateRule(entry);
        return Success(rule.id);
      }
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  @override
  Future<Result<bool, AppError>> delete(int id) async {
    try {
      final deleted = await _db.smartRuleDao.deleteRule(id);
      return Success(deleted > 0);
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  @override
  Future<Result<bool, AppError>> toggle(int id, bool active) async {
    try {
      final entry = await _db.smartRuleDao.getById(id);
      if (entry == null) {
        return Failure(AppError.notFound('Smart rule not found'));
      }
      final updated = entry.copyWith(isActive: active);
      await _db.smartRuleDao.updateRule(updated);
      return const Success(true);
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }
}