import '../../../core/utils/result.dart';
import 'category_model.dart';

abstract class CategoryRepositoryInterface {
  Stream<List<CategoryModel>> watchAll();
  Stream<List<CategoryModel>> watchExpenses();
  Stream<List<CategoryModel>> watchIncomes();
  Future<Result<List<CategoryModel>, AppError>> getAll();
  Future<Result<CategoryModel, AppError>> getByKey(String key);
  Future<Result<CategoryModel, AppError>> getById(int id);
  Future<Result<int, AppError>> createCategory({
    required String key,
    required String name,
    String? nameId,
    required String icon,
    required String color,
    bool isIncome = false,
  });
  Future<Result<bool, AppError>> updateCategory(CategoryModel category);
  Future<Result<int, AppError>> deleteCategory(int id);
}
