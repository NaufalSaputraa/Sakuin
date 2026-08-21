import '../../../core/utils/result.dart';
import '../../../services/export/export_model.dart';

abstract class BackupRepositoryInterface {
  Future<ExportBundle> exportAll();
  Future<Result<ImportResult, AppError>> importAll(ExportBundle bundle);
}