import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'smart_rule_dao.g.dart';

@DriftAccessor(tables: [SmartRules])
class SmartRuleDao extends DatabaseAccessor<AppDatabase> with _$SmartRuleDaoMixin {
  SmartRuleDao(super.db);

  Stream<List<SmartRuleEntry>> watchAll() {
    return (select(smartRules)..orderBy([(t) => OrderingTerm(expression: t.priority)])).watch();
  }

  Stream<List<SmartRuleEntry>> watchActive() {
    return (select(smartRules)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.priority)]))
        .watch();
  }

  Future<List<SmartRuleEntry>> getActive() {
    return (select(smartRules)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.priority)]))
        .get();
  }

  Future<SmartRuleEntry?> getById(int id) {
    return (select(smartRules)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertRule(SmartRulesCompanion companion) {
    return into(smartRules).insert(companion);
  }

  Future<bool> updateRule(SmartRuleEntry entry) {
    return update(smartRules).replace(entry);
  }

  Future<int> deleteRule(int id) {
    return (delete(smartRules)..where((t) => t.id.equals(id))).go();
  }

  Future<List<SmartRuleEntry>> getByPriority(int priority) {
    return (select(smartRules)
          ..where((t) => t.priority.equals(priority))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }
}