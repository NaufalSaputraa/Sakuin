import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/model_download_constants.dart';
import '../../../core/utils/result.dart';

/// Lifecycle states for the on-device LLM model.
enum ModelState {
  notDownloaded,
  downloading,
  loading,
  ready,
  error,
}

/// Repository responsible for downloading, verifying, and tracking the
/// on-device `.litertlm` model. It is intentionally model-agnostic: it only
/// consumes [ModelDownloadConfig], so swapping Qwen -> Gemma 4 E2B requires
/// no changes here.
class ModelRepository {
  ModelRepository({Dio? dio}) : _dio = dio ?? Dio() {
    _emit(_currentState = ModelState.notDownloaded);
    refreshModelState();
  }

  final Dio _dio;
  final StreamController<ModelState> _stateController =
      StreamController<ModelState>.broadcast();

  ModelState _currentState = ModelState.notDownloaded;
  String? _lastError;
  CancelToken? _cancelToken;

  ModelState get currentState => _currentState;
  String? get lastError => _lastError;
  Stream<ModelState> get modelStateStream => _stateController.stream;

  void _emit(ModelState state) {
    _currentState = state;
    if (!_stateController.isClosed) _stateController.add(state);
  }

  /// Absolute path to the model file on device.
  Future<String> getModelPath() async {
    final base =
        await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final modelsDir = Directory(p.join(base.path, 'models'));
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return p.join(modelsDir.path, ModelDownloadConfig.modelFileName);
  }

  /// Re-evaluates whether the model file is present and updates [ModelState].
  Future<void> refreshModelState() async {
    if (await isModelDownloaded()) {
      _emit(ModelState.ready);
    } else {
      _emit(ModelState.notDownloaded);
    }
  }

  /// Quick existence + non-empty check (no hash, for performance).
  Future<bool> isModelDownloaded() async {
    try {
      final file = File(await getModelPath());
      if (!await file.exists()) return false;
      return await file.length() > 0;
    } catch (_) {
      return false;
    }
  }

  /// Verifies the downloaded file's SHA-256 against the pinned hash.
  /// When the pinned hash is still a placeholder, integrity is accepted
  /// (dev mode) but size/existence are still enforced by callers.
  Future<Result<bool, AppError>> verifyModelIntegrity() async {
    try {
      final file = File(await getModelPath());
      if (!await file.exists()) {
        return Failure(AppError.notFound('Model file not found'));
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return Failure(AppError.validation('Model file is empty'));
      }
      const expected = ModelDownloadConfig.modelSha256;
      if (expected.startsWith('PLACEHOLDER')) {
        // No pinned hash yet — accept (dev mode).
        return const Success(true);
      }
      final digest = sha256.convert(bytes);
      final actual = digest.toString().toLowerCase();
      if (actual == expected.toLowerCase()) {
        return const Success(true);
      }
      return Failure(AppError.validation('llm.verifyFailed'));
    } catch (e) {
      return Failure(AppError.parse('Failed to verify model: $e'));
    }
  }

  /// After a download completes, verify integrity and either mark READY or
  /// delete the corrupt file and move to ERROR.
  Future<Result<void, AppError>> finalizeDownloadedModel() async {
    final verify = await verifyModelIntegrity();
    if (verify.isFailure) {
      final path = await getModelPath();
      final file = File(path);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {
          /* ignore */
        }
      }
      _lastError = verify.errorOrNull?.message;
      _emit(ModelState.error);
      return verify;
    }
    _lastError = null;
    _emit(ModelState.ready);
    return const Success(null);
  }

  /// Starts the model download. Reports progress in bytes via [onProgress].
  /// Returns a [Result] so callers can surface specific failures
  /// (insufficient space, network, cancelled, hash mismatch).
  Future<Result<void, AppError>> startDownload({
    required void Function(int receivedBytes, int totalBytes) onProgress,
  }) async {
    _lastError = null;
    _emit(ModelState.downloading);
    _cancelToken = CancelToken();

    try {
      final path = await getModelPath();
      await _dio.download(
        ModelDownloadConfig.modelUrl,
        path,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          onProgress(received, total < 0 ? 0 : total);
        },
      );
      return await finalizeDownloadedModel();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        _emit(ModelState.notDownloaded);
        return Failure(AppError.validation('Download cancelled'));
      }
      if (_isInsufficientSpace(e)) {
        _lastError = 'llm.insufficientSpace';
        _emit(ModelState.error);
        return Failure(AppError.validation('llm.insufficientSpace'));
      }
      _lastError = e.message ?? 'Download failed';
      _emit(ModelState.error);
      return Failure(AppError.parse('Download failed: ${e.message}'));
    } on FileSystemException catch (e) {
      if (_isInsufficientSpace(e)) {
        _lastError = 'llm.insufficientSpace';
        _emit(ModelState.error);
        return Failure(AppError.validation('llm.insufficientSpace'));
      }
      _lastError = e.message;
      _emit(ModelState.error);
      return Failure(AppError.parse('Download failed: ${e.message}'));
    } catch (e) {
      _lastError = e.toString();
      _emit(ModelState.error);
      return Failure(AppError.parse('Download failed: $e'));
    } finally {
      _cancelToken = null;
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel('User cancelled');
    _cancelToken = null;
  }

  bool _isInsufficientSpace(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('no space') ||
        msg.contains('enospc') ||
        msg.contains('insufficient') ||
        msg.contains('storage');
  }

  void dispose() {
    _cancelToken?.cancel();
    _stateController.close();
  }
}

/// Provider exposing the singleton [ModelRepository].
final modelRepositoryProvider = Provider<ModelRepository>((ref) {
  final repo = ModelRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Convenience async provider for the current [ModelState].
final modelStateStreamProvider = StreamProvider<ModelState>((ref) {
  final repo = ref.watch(modelRepositoryProvider);
  return repo.modelStateStream;
});
