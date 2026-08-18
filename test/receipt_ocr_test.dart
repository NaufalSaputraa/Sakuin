import 'package:flutter_test/flutter_test.dart';
import 'package:sakuin_app/services/ocr/receipt_scanner_service.dart';

void main() {
  group('ReceiptScannerService OCR Text Parsing Tests', () {
    final scanner = ReceiptScannerService();

    test('parses Indomaret paper receipt accurately', () {
      const sampleIndomaret = '''
        INDOMARET KEMANG
        PT INDOMARCO PRISMATAMA
        ROTI TAWAR SARI ROTI    15.000
        ULTRA MILK COKLAT 250ML  7.500
        AIR MINERAL 600ML        3.500
        SUBTOTAL               26.000
        TOTAL BAYAR            26.000
        TUNAI                  50.000
        KEMBALI                24.000
      ''';

      final res = scanner.parseReceiptText(sampleIndomaret);
      expect(res.title, 'Indomaret');
      expect(res.amount, 26000);
      expect(res.categoryKey, 'shopping');
      expect(res.walletProvider, 'physical');
    });

    test('parses BCA Mobile screenshot transfer slip', () {
      const sampleBca = '''
        m-Transfer:
        BERHASIL
        16/08/2026 14:32:10
        Transfer ke: 1234567890
        Nama: BUDI SANTOSO
        Jumlah: Rp 250.000
        Berita: Bayar sewa kos
      ''';

      final res = scanner.parseReceiptText(sampleBca);
      expect(res.title, 'Transfer BCA');
      expect(res.amount, 250000);
      expect(res.walletProvider, 'bank');
    });

    test('parses SPBU Pertamina receipt', () {
      const samplePertamina = '''
        SPBU 31.12345 PERTAMINA
        JL. SUDIRMAN NO. 10
        PERTALITE
        LITER: 5.00
        HARGA/LITER: Rp 10.000
        TOTAL: Rp 50.000
        METODE: CASH
      ''';

      final res = scanner.parseReceiptText(samplePertamina);
      expect(res.title, 'SPBU Pertamina');
      expect(res.amount, 50000);
      expect(res.categoryKey, 'fuel');
      expect(res.walletProvider, 'physical');
    });
  });
}
