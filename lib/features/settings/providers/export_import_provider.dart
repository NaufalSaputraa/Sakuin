import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/database/app_database.dart';
import '../../../services/export/export_model.dart';
import '../../../services/export/export_service.dart';
import '../../../services/export/import_service.dart';
import '../data/backup_repository.dart';
import '../domain/backup_repository_interface.dart';

class ExportImportState {
  final bool isExporting;
  final bool isImporting;
  final double progress;
  final ImportResult? lastResult;
  final String? error;

  const ExportImportState({
    this.isExporting = false,
    this.isImporting = false,
    this.progress = 0.0,
    this.lastResult,
    this.error,
  });

  ExportImportState copyWith({
    bool? isExporting,
    bool? isImporting,
    double? progress,
    ImportResult? lastResult,
    String? error,
  }) {
    return ExportImportState(
      isExporting: isExporting ?? this.isExporting,
      isImporting: isImporting ?? this.isImporting,
      progress: progress ?? this.progress,
      lastResult: lastResult ?? this.lastResult,
      error: error ?? this.error,
    );
  }
}

class ExportImportNotifier extends Notifier<ExportImportState> {
  late final BackupRepositoryInterface _backupRepo;
  late final ExportService _exportService;
  late final ImportService _importService;

  @override
  ExportImportState build() {
    _backupRepo = ref.read(backupRepositoryProvider);
    _exportService = const ExportService();
    _importService = const ImportService();
    return const ExportImportState();
  }

  Future<void> pickAndExportCsv() async {
    state = state.copyWith(isExporting: true, progress: 0.1, error: null);

    try {
      // Export all data
      state = state.copyWith(progress: 0.3);
      final bundle = await _backupRepo.exportAll();

      state = state.copyWith(progress: 0.6);
      final csvString = await _exportService.toCsv(bundle);

      state = state.copyWith(progress: 0.8);
      // Save to file
      // file_picker 12: static entry point; saveFile writes [bytes] itself
      // and returns the saved file Uri (null when cancelled).
      final output = await FilePicker.saveFile(
        dialogTitle: 'Save CSV Export',
        fileName: 'sakuin_transactions_${DateTime.now().toIso8601String().split('T').first}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: Uint8List.fromList(csvString.codeUnits),
      );

      state = state.copyWith(progress: 1.0);
      if (output != null) {
        state = state.copyWith(
          isExporting: false,
          lastResult: ImportResult(
            insertedCounts: {'transactions': bundle.transactions.length},
            warnings: [],
          ),
        );
      } else {
        state = state.copyWith(isExporting: false, error: 'Export cancelled');
      }
    } catch (e) {
      state = state.copyWith(isExporting: false, error: 'Export failed: $e');
    }
  }

  Future<void> pickAndExportJson() async {
    state = state.copyWith(isExporting: true, progress: 0.1, error: null);

    try {
      state = state.copyWith(progress: 0.3);
      final bundle = await _backupRepo.exportAll();

      state = state.copyWith(progress: 0.6);
      final jsonString = await _exportService.toJson(bundle);

      state = state.copyWith(progress: 0.8);
      final output = await FilePicker.saveFile(
        dialogTitle: 'Save JSON Export',
        fileName: 'sakuin_backup_${DateTime.now().toIso8601String().split('T').first}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(jsonString.codeUnits),
      );

      state = state.copyWith(progress: 1.0);
      if (output != null) {
        state = state.copyWith(
          isExporting: false,
          lastResult: ImportResult(
            insertedCounts: {
              'wallets': bundle.wallets.length,
              'categories': bundle.categories.length,
              'transactions': bundle.transactions.length,
              'budgets': bundle.budgets.length,
              'smartRules': bundle.smartRules.length,
            },
            warnings: [],
          ),
        );
      } else {
        state = state.copyWith(isExporting: false, error: 'Export cancelled');
      }
    } catch (e) {
      state = state.copyWith(isExporting: false, error: 'Export failed: $e');
    }
  }

  Future<void> pickAndImport() async {
    state = state.copyWith(isImporting: true, progress: 0.1, error: null);

    try {
      // file_picker 12: pickFile returns a single PlatformFile? (null when
      // cancelled); bytes are read lazily via readAsBytes().
      final file = await FilePicker.pickFile(
        dialogTitle: 'Select Backup File',
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
      );

      if (file == null) {
        state = state.copyWith(isImporting: false, error: 'Import cancelled');
        return;
      }

      final extension =
          file.name.contains('.') ? file.name.split('.').last.toLowerCase() : '';
      final bytes = await file.readAsBytes();

      state = state.copyWith(progress: 0.3);
      final content = String.fromCharCodes(bytes);

      ExportBundle bundle;
      if (extension == 'json') {
        final parseResult = await _importService.parseJson(content);
        if (parseResult.isFailure) {
          state = state.copyWith(isImporting: false, error: parseResult.errorOrNull!.message);
          return;
        }
        bundle = parseResult.valueOrNull!;
      } else if (extension == 'csv') {
        final parseResult = await _importService.parseCsv(content);
        if (parseResult.isFailure) {
          state = state.copyWith(isImporting: false, error: parseResult.errorOrNull!.message);
          return;
        }
        bundle = parseResult.valueOrNull!;
      } else {
        state = state.copyWith(isImporting: false, error: 'Unsupported file format');
        return;
      }

      state = state.copyWith(progress: 0.6);
      final importResult = await _backupRepo.importAll(bundle);

      state = state.copyWith(progress: 1.0);
      if (importResult.isSuccess) {
        state = state.copyWith(
          isImporting: false,
          lastResult: importResult.valueOrNull,
        );
      } else {
        state = state.copyWith(
          isImporting: false,
          error: importResult.errorOrNull!.message,
        );
      }
    } catch (e) {
      state = state.copyWith(isImporting: false, error: 'Import failed: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearResult() {
    state = state.copyWith(lastResult: null);
  }
}

final backupRepositoryProvider = Provider<BackupRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return BackupRepository(db);
});

final exportImportNotifierProvider = NotifierProvider<ExportImportNotifier, ExportImportState>(() {
  return ExportImportNotifier();
});