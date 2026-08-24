// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_rule_dao.dart';

// ignore_for_file: type=lint
mixin _$SmartRuleDaoMixin on DatabaseAccessor<AppDatabase> {
  $SmartRulesTable get smartRules => attachedDatabase.smartRules;
  SmartRuleDaoManager get managers => SmartRuleDaoManager(this);
}

class SmartRuleDaoManager {
  final _$SmartRuleDaoMixin _db;
  SmartRuleDaoManager(this._db);
  $$SmartRulesTableTableManager get smartRules =>
      $$SmartRulesTableTableManager(_db.attachedDatabase, _db.smartRules);
}
