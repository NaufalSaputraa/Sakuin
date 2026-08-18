import 'package:flutter_test/flutter_test.dart';
import 'package:sakuin_app/core/utils/currency_formatter.dart';

void main() {
  group('IndonesianAmountParser Tests', () {
    test('parses basic integer and shorthand units correctly', () {
      expect(IndonesianAmountParser.parse('25rb'), 25000);
      expect(IndonesianAmountParser.parse('25k'), 25000);
      expect(IndonesianAmountParser.parse('50ribu'), 50000);
      expect(IndonesianAmountParser.parse('1.5jt'), 1500000);
      expect(IndonesianAmountParser.parse('2juta'), 2000000);
      expect(IndonesianAmountParser.parse('500k'), 500000);
    });

    test('parses Rupiah formatted strings', () {
      expect(IndonesianAmountParser.parse('Rp 50.000'), 50000);
      expect(IndonesianAmountParser.parse('Rp. 100.000'), 100000);
      expect(IndonesianAmountParser.parse('10000'), 10000);
    });

    test('returns null on invalid string', () {
      expect(IndonesianAmountParser.parse(''), isNull);
      expect(IndonesianAmountParser.parse('abc'), isNull);
    });
  });

  group('RupiahFormatter Tests', () {
    test('formats positive amounts without decimals', () {
      expect(RupiahFormatter.format(50000), 'Rp 50.000');
      expect(RupiahFormatter.format(1500000), 'Rp 1.500.000');
    });

    test('formats compact representations', () {
      expect(RupiahFormatter.compact(50000), '50 rb');
      expect(RupiahFormatter.compact(1500000), '1,5 jt');
      expect(RupiahFormatter.compact(2000000000), '2 M');
    });
  });
}
