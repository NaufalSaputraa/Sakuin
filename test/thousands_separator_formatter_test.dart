import 'package:flutter_test/flutter_test.dart';
import 'package:sakuin_app/core/utils/thousands_separator_formatter.dart';

void main() {
  group('ThousandsSeparatorInputFormatter', () {
    final formatter = ThousandsSeparatorInputFormatter();

    test('formats 100000 to 100.000', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '100000'),
      );
      expect(result.text, '100.000');
    });

    test('formats 1000 to 1.000', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1000'),
      );
      expect(result.text, '1.000');
    });

    test('formats 100 to 100', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '100'),
      );
      expect(result.text, '100');
    });

    test('returns empty string when input is cleared', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '100.000'),
        TextEditingValue.empty,
      );
      expect(result.text, '');
    });

    test('formats 1500000 to 1.500.000', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1500000'),
      );
      expect(result.text, '1.500.000');
    });
  });
}
