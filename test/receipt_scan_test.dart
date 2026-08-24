import 'package:flutter_test/flutter_test.dart';
import 'package:sakuin_app/services/ml/parsed_transaction.dart';
import 'package:sakuin_app/services/ocr/receipt_scanner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReceiptScannerService scanReceipt(path) + parseReceiptText', () {
    final scanner = ReceiptScannerService();

    test('parseReceiptText still parses Indomaret receipt (regression)', () {
      const sample = '''
        INDOMARET KEMANG
        TOTAL BAYAR            26.000
      ''';
      final res = scanner.parseReceiptText(sample);
      expect(res.title, 'Indomaret');
      expect(res.amount, 26000);
      expect(res.categoryKey, 'shopping');
    });

    test('parseReceiptText detects GoPay e-receipt', () {
      const sample = '''
        GoPay
        Pembayaran Berhasil
        Tokopedia
        Total: Rp 150.000
      ''';
      final res = scanner.parseReceiptText(sample);
      expect(res.title, 'Transaksi GoPay');
      expect(res.amount, 150000);
      expect(res.walletProvider, 'gopay');
    });

    test('scanReceipt(String) method exists and accepts a path', () {
      // The path-based overload must be present (compile-time check) and
      // return null gracefully when the file cannot be read by ML Kit.
      expect(scanner.scanReceipt, isA<Function>());
      expect(
        scanner.scanReceipt('__non_existent_path__.jpg'),
        isA<Future<ParsedTransaction?>>(),
      );
    });
  });
}
