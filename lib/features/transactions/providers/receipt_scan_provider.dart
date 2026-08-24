import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/result.dart';
import '../../../services/ocr/camera_service.dart';
import '../../../services/ocr/receipt_scanner_service.dart';
import '../../../services/ml/parsed_transaction.dart';

class ReceiptScanState {
  final bool isLoading;
  final String? previewPath;
  final ParsedTransaction? parsed;
  final String? error; // localized key (e.g. 'ocr.errorPermission')

  const ReceiptScanState({
    this.isLoading = false,
    this.previewPath,
    this.parsed,
    this.error,
  });

  ReceiptScanState copyWith({
    bool? isLoading,
    String? previewPath,
    ParsedTransaction? parsed,
    String? error,
    bool clearError = false,
    bool clearParsed = false,
  }) {
    return ReceiptScanState(
      isLoading: isLoading ?? this.isLoading,
      previewPath: previewPath ?? this.previewPath,
      parsed: clearParsed ? null : (parsed ?? this.parsed),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ReceiptScanNotifier extends Notifier<ReceiptScanState> {
  @override
  ReceiptScanState build() => const ReceiptScanState();

  Future<void> pickFromCamera() async {
    final camera = ref.read(cameraServiceProvider);
    final result = await camera.pickAndCropFromCamera();
    await result.when(
      success: (path) => scan(path),
      failure: (e) async {
        state = state.copyWith(
          isLoading: false,
          error: e is PermissionError ? 'ocr.errorPermission' : 'ocr.errorScan',
          clearParsed: true,
        );
      },
    );
  }

  Future<void> pickFromGallery() async {
    final camera = ref.read(cameraServiceProvider);
    final result = await camera.pickAndCropFromGallery();
    await result.when(
      success: (path) => scan(path),
      failure: (e) async {
        state = state.copyWith(
          isLoading: false,
          error: e is PermissionError ? 'ocr.errorPermission' : 'ocr.errorScan',
          clearParsed: true,
        );
      },
    );
  }

  /// Run OCR on an already-cropped image at [path] and store the result.
  Future<void> scan(String path) async {
    state = state.copyWith(
      isLoading: true,
      previewPath: path,
      error: null,
      clearParsed: true,
    );

    final scanner = ref.read(receiptScannerServiceProvider);
    try {
      final parsed = await scanner.scanReceipt(path);
      state = state.copyWith(
        isLoading: false,
        parsed: parsed,
        error: parsed == null ? 'ocr.errorScan' : null,
      );
    } on Exception catch (_) {
      state = state.copyWith(isLoading: false, error: 'ocr.errorScan', clearParsed: true);
    }
  }

  void clear() {
    state = const ReceiptScanState();
  }
}

final receiptScanProvider =
    NotifierProvider<ReceiptScanNotifier, ReceiptScanState>(() {
  return ReceiptScanNotifier();
});
