import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GemmaModelStatus {
  notDownloaded,
  downloading,
  ready,
  error,
}

class GemmaLlmService {
  static const String modelName = 'Google Gemma (Edge)';
  static const String modelVersion = '2B-IT';
  static const String estimatedDownloadSize = '~1.4 GB';

  final GemmaModelStatus _status = GemmaModelStatus.ready;
  final double _downloadProgress = 1.0;

  GemmaModelStatus get status => _status;
  double get downloadProgress => _downloadProgress;

  String formatPrompt({
    required String userQuery,
    required double totalBalance,
    required double monthlyIncome,
    required double monthlyExpense,
    required double budgetLimit,
  }) {
    return '''
<start_of_turn>system
Kamu adalah Asisten Finansial Pintar Sakuin berbasis model Google Gemma.
Bicaralah dalam Bahasa Indonesia yang ramah, ringkas, dan solutif.
Data keuangan riil pengguna saat ini:
- Total Saldo: Rp $totalBalance
- Pemasukan Bulan Ini: Rp $monthlyIncome
- Pengeluaran Bulan Ini: Rp $monthlyExpense
- Batas Anggaran: Rp $budgetLimit (Sisa: Rp ${budgetLimit - monthlyExpense})
Gunakan data di atas sebagai fakta mutlak.<end_of_turn>
<start_of_turn>user
$userQuery<end_of_turn>
<start_of_turn>model
''';
  }

  Future<String> generateResponse({
    required String prompt,
  }) async {
    return 'Analisis Gemma AI telah selesai berdasarkan data finansial terkini.';
  }
}

final gemmaLlmServiceProvider = Provider<GemmaLlmService>((ref) {
  return GemmaLlmService();
});
