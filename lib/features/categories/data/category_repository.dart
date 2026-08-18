import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/result.dart';
import '../domain/category_model.dart';
import '../domain/category_repository_interface.dart';

class CategoryRepository implements CategoryRepositoryInterface {
  final AppDatabase _db;

  CategoryRepository(this._db);

  @override
  Stream<List<CategoryModel>> watchAll() {
    return _db.categoryDao.watchAll().map((list) => list.map((e) => CategoryModel.fromEntry(e)).toList());
  }

  @override
  Stream<List<CategoryModel>> watchExpenses() {
    return _db.categoryDao.watchExpenses().map((list) => list.map((e) => CategoryModel.fromEntry(e)).toList());
  }

  @override
  Stream<List<CategoryModel>> watchIncomes() {
    return _db.categoryDao.watchIncomes().map((list) => list.map((e) => CategoryModel.fromEntry(e)).toList());
  }

  @override
  Future<Result<List<CategoryModel>, AppError>> getAll() async {
    try {
      final entries = await _db.categoryDao.getAll();
      return Success(entries.map((e) => CategoryModel.fromEntry(e)).toList());
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<CategoryModel, AppError>> getByKey(String key) async {
    try {
      final entry = await _db.categoryDao.getByKey(key);
      if (entry == null) return const Failure(NotFoundError('Category not found'));
      return Success(CategoryModel.fromEntry(entry));
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<CategoryModel, AppError>> getById(int id) async {
    try {
      final entry = await _db.categoryDao.getById(id);
      if (entry == null) return const Failure(NotFoundError('Category not found'));
      return Success(CategoryModel.fromEntry(entry));
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<int, AppError>> createCategory({
    required String key,
    required String name,
    String? nameId,
    required String icon,
    required String color,
    bool isIncome = false,
  }) async {
    try {
      final id = await _db.categoryDao.insertCategory(
        CategoriesCompanion.insert(
          key: key,
          name: name,
          nameId: Value(nameId),
          icon: icon,
          color: color,
          isDefault: const Value(false),
          isIncome: Value(isIncome),
          sortOrder: const Value(99),
        ),
      );
      return Success(id);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<bool, AppError>> updateCategory(CategoryModel category) async {
    try {
      final success = await _db.categoryDao.updateCategory(
        CategoryEntry(
          id: category.id,
          key: category.key,
          name: category.name,
          nameId: category.nameId,
          icon: category.icon,
          color: category.color,
          parentId: category.parentId,
          isDefault: category.isDefault,
          isIncome: category.isIncome,
          sortOrder: category.sortOrder,
        ),
      );
      return Success(success);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<int, AppError>> deleteCategory(int id) async {
    try {
      final rows = await _db.categoryDao.deleteCategory(id);
      return Success(rows);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }
}
