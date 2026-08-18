import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../data/category_repository.dart';
import '../domain/category_model.dart';
import '../domain/category_repository_interface.dart';

final categoryRepositoryProvider = Provider<CategoryRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryRepository(db);
});

final allCategoriesProvider = StreamProvider.autoDispose<List<CategoryModel>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchAll();
});

final expenseCategoriesProvider = StreamProvider.autoDispose<List<CategoryModel>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchExpenses();
});

final incomeCategoriesProvider = StreamProvider.autoDispose<List<CategoryModel>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchIncomes();
});
