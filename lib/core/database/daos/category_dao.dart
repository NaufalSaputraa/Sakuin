import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories, Transactions])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Stream<List<CategoryEntry>> watchAll() {
    return (select(categories)..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).watch();
  }

  Future<List<CategoryEntry>> getAll() {
    return (select(categories)..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).get();
  }

  Stream<List<CategoryEntry>> watchExpenses() {
    return (select(categories)
          ..where((t) => t.isIncome.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .watch();
  }

  Stream<List<CategoryEntry>> watchIncomes() {
    return (select(categories)
          ..where((t) => t.isIncome.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .watch();
  }

  Future<CategoryEntry?> getByKey(String key) {
    return (select(categories)..where((t) => t.key.equals(key))).getSingleOrNull();
  }

  Future<CategoryEntry?> getById(int id) {
    return (select(categories)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertCategory(CategoriesCompanion companion) {
    return into(categories).insert(companion);
  }

  Future<bool> updateCategory(CategoryEntry entry) {
    return update(categories).replace(entry);
  }

  Future<int> deleteCategory(int id) {
    return (delete(categories)..where((t) => t.id.equals(id))).go();
  }
}
