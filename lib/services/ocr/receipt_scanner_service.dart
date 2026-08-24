import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/transactions/domain/transaction_model.dart';
import '../ml/parsed_transaction.dart';

enum ReceiptSource {
  camera,
  gallery,
}

class ReceiptScannerService {
  final ImagePicker _picker = ImagePicker();

  /// Legacy entry point: pick an image from [source] then OCR it.
  ///
  /// Kept for backward compatibility (e.g. quick-action shortcuts). Prefer the
  /// new [scanReceipt] path-based flow for the full camera → crop → OCR pipeline.
  Future<ParsedTransaction?> scanReceiptFromSource({required ReceiptSource source}) async {
    final imageSource = source == ReceiptSource.camera ? ImageSource.camera : ImageSource.gallery;
    final pickedFile = await _picker.pickImage(
      source: imageSource,
      imageQuality: 90,
    );

    if (pickedFile == null) return null;

    return scanReceipt(pickedFile.path);
  }

  /// OCR a pre-captured (and ideally cropped) image at [croppedImagePath].
  ///
  /// Loads the image, runs ML Kit [TextRecognizer] (latin script), then routes
  /// the recognized text through [parseReceiptText]. Returns a structured
  /// [ParsedTransaction], or `null` if no text could be recognized.
  Future<ParsedTransaction?> scanReceipt(String croppedImagePath) async {
    final inputImage = InputImage.fromFilePath(croppedImagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      return parseReceiptText(recognizedText.text);
    } finally {
      await textRecognizer.close();
    }
  }

  ParsedTransaction parseReceiptText(String rawText) {
    if (rawText.trim().isEmpty) {
      return const ParsedTransaction(
        title: 'Struk Belanja',
        rawInput: '',
        confidence: 0.0,
      );
    }

    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // 1. Detect Merchant Name (Usually top 1-3 lines or known brand keywords)
    String merchant = 'Struk Pembelian';
    String? categoryKey;
    String? walletProvider;

    final fullLower = rawText.toLowerCase();

    // Known Merchants & Categories
    if (fullLower.contains('indomaret')) {
      merchant = 'Indomaret';
      categoryKey = 'shopping';
    } else if (fullLower.contains('alfamart') || fullLower.contains('alfamidi')) {
      merchant = 'Alfamart';
      categoryKey = 'shopping';
    } else if (fullLower.contains('spbu') || fullLower.contains('pertamina') || fullLower.contains('shell')) {
      merchant = 'SPBU Pertamina';
      categoryKey = 'fuel';
    } else if (fullLower.contains('mcdonald') || fullLower.contains('kfc') || fullLower.contains('starbucks')) {
      merchant = 'Restoran';
      categoryKey = 'food';
    } else if (fullLower.contains('bca') || fullLower.contains('m-bca') || fullLower.contains('m-transfer') || fullLower.contains('klikbca')) {
      merchant = 'Transfer BCA';
      walletProvider = 'bank';
    } else if (fullLower.contains('gopay') || fullLower.contains('gojek')) {
      merchant = 'Transaksi GoPay';
      walletProvider = 'gopay';
    } else if (fullLower.contains('ovo') || fullLower.contains('grab')) {
      merchant = 'Transaksi OVO';
      walletProvider = 'ovo';
    } else if (fullLower.contains('dana')) {
      merchant = 'Transaksi Dana';
      walletProvider = 'dana';
    } else if (fullLower.contains('shopee')) {
      merchant = 'Shopee / ShopeePay';
      walletProvider = 'shopeepay';
      categoryKey = 'shopping';
    } else if (lines.isNotEmpty) {
      // Fallback: take first non-empty line as merchant
      merchant = lines.first;
    }

    // 2. Extract Total Amount
    double? totalAmount;

    // Look for lines containing "TOTAL", "JUMLAH", "SUBTOTAL", "BAYAR", "TAGIHAN", "RP"
    final totalKeywords = RegExp(r'(total|jumlah|grand\s*total|subtotal|tagihan|nominal|rp\.?)', caseSensitive: false);

    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      if (totalKeywords.hasMatch(line)) {
        final parsed = IndonesianAmountParser.parse(line);
        if (parsed != null && parsed > 0) {
          totalAmount = parsed;
          break;
        }
      }
    }

    // If still null, search for the maximum amount found across all lines
    if (totalAmount == null) {
      double maxFound = 0.0;
      for (final line in lines) {
        final parsed = IndonesianAmountParser.parse(line);
        if (parsed != null && parsed > maxFound) {
          maxFound = parsed;
        }
      }
      if (maxFound > 0) totalAmount = maxFound;
    }

    return ParsedTransaction(
      amount: totalAmount,
      categoryKey: categoryKey ?? 'shopping',
      walletProvider: walletProvider ?? 'physical',
      transactionType: TransactionType.expense,
      title: merchant,
      confidence: totalAmount != null ? 0.85 : 0.4,
      rawInput: rawText,
    );
  }
}

final receiptScannerServiceProvider = Provider<ReceiptScannerService>((ref) {
  return ReceiptScannerService();
});
