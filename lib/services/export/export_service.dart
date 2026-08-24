import 'dart:convert';
import 'export_model.dart';

class ExportService {
  const ExportService();

  Future<String> toJson(ExportBundle bundle) async {
    final jsonMap = bundle.toJson();
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(jsonMap);
  }

  Future<String> toCsv(ExportBundle bundle) async {
    final buffer = StringBuffer();

    // CSV Header for transactions only
    buffer.writeln('id,walletId,categoryId,amount,type,title,date');

    for (final tx in bundle.transactions) {
      final categoryId = tx.categoryId?.toString() ?? '';
      final description = tx.description?.replaceAll('"', '""') ?? '';
      final merchant = tx.merchant?.replaceAll('"', '""') ?? '';
      final title = tx.title.replaceAll('"', '""');

      // Escape fields that contain commas or quotes
      final escapedTitle = title.contains(',') || title.contains('"')
          ? '"$title"'
          : title;
      final escapedDesc = description.contains(',') || description.contains('"')
          ? '"$description"'
          : description;
      final escapedMerchant = merchant.contains(',') || merchant.contains('"')
          ? '"$merchant"'
          : merchant;

      buffer.write('${tx.id},');
      buffer.write('${tx.walletId},');
      buffer.write('$categoryId,');
      buffer.write('${tx.amount},');
      buffer.write('${tx.transactionType.name},');
      buffer.write('$escapedTitle,');
      buffer.write(tx.transactionDate.toIso8601String());

      // Add optional fields as extra columns for completeness
      buffer.write(',$escapedDesc');
      buffer.write(',$escapedMerchant');
      buffer.write(',${tx.sourceInput}');
      buffer.write(',${tx.rawInput ?? ''}');
      buffer.write(',${tx.transferToWalletId ?? ''}');
      buffer.write(',${tx.createdAt.toIso8601String()}');
      buffer.write(',${tx.updatedAt.toIso8601String()}');
      buffer.writeln();
    }

    return buffer.toString();
  }
}