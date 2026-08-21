import '../../features/transactions/domain/transaction_model.dart';

class DetectedSubscription {
  final String merchant;
  final String normalizedKey;
  final double amount;
  final String period;
  final int occurrenceCount;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final double confidence;
  final int? categoryId;
  final DateTime nextChargeEstimate;

  const DetectedSubscription({
    required this.merchant,
    required this.normalizedKey,
    required this.amount,
    required this.period,
    required this.occurrenceCount,
    required this.firstSeen,
    required this.lastSeen,
    required this.confidence,
    this.categoryId,
    required this.nextChargeEstimate,
  });
}

class SubscriptionDetectorService {
  static const double _amountTolerance = 0.05; // ±5%
  static const int _minOccurrences = 2;
  static const int _expectedIntervalDays = 30;
  static const int _intervalToleranceDays = 5;

  List<DetectedSubscription> detect(List<TransactionModel> transactions) {
    // Filter expense transactions with merchant
    final expenseTxs = transactions
        .where((tx) => tx.isExpense && tx.merchant != null && tx.merchant!.trim().isNotEmpty)
        .toList();

    if (expenseTxs.length < _minOccurrences) return [];

    // Group by normalized merchant key
    final groups = <String, List<TransactionModel>>{};
    for (final tx in expenseTxs) {
      final key = _normalizeMerchantKey(tx.merchant!);
      groups.putIfAbsent(key, () => []).add(tx);
    }

    final detected = <DetectedSubscription>[];

    for (final entry in groups.entries) {
      final key = entry.key;
      final txs = entry.value;

      if (txs.length < _minOccurrences) continue;

      // Sort by date
      txs.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

      // Check amount consistency (±5%)
      final amounts = txs.map((t) => t.amount).toList();
      final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
      final allWithinTolerance = amounts.every((amt) {
        final diff = (amt - avgAmount).abs() / avgAmount;
        return diff <= _amountTolerance;
      });

      if (!allWithinTolerance) continue;

      // Check interval regularity (~30 days ±5)
      final intervals = <int>[];
      for (int i = 1; i < txs.length; i++) {
        final diff = txs[i].transactionDate.difference(txs[i - 1].transactionDate).inDays;
        intervals.add(diff);
      }

      if (intervals.isEmpty) continue;

      final medianInterval = _median(intervals);
      final isRegular = (medianInterval - _expectedIntervalDays).abs() <= _intervalToleranceDays;

      if (!isRegular) continue;

      // Calculate confidence based on regularity and count
      final confidence = _calculateConfidence(intervals, txs.length, avgAmount, amounts);

      // Get most common category
      final categoryId = _getMostCommonCategoryId(txs);

      // Next charge estimate
      final nextCharge = txs.last.transactionDate.add(const Duration(days: _expectedIntervalDays));

      detected.add(DetectedSubscription(
        merchant: txs.first.merchant!,
        normalizedKey: key,
        amount: avgAmount,
        period: 'monthly',
        occurrenceCount: txs.length,
        firstSeen: txs.first.transactionDate,
        lastSeen: txs.last.transactionDate,
        confidence: confidence,
        categoryId: categoryId,
        nextChargeEstimate: nextCharge,
      ));
    }

    // Sort by confidence descending
    detected.sort((a, b) => b.confidence.compareTo(a.confidence));
    return detected;
  }

  String _normalizeMerchantKey(String merchant) {
    return merchant
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  int _median(List<int> values) {
    final sorted = List<int>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length % 2 == 0) {
      return (sorted[mid - 1] + sorted[mid]) ~/ 2;
    }
    return sorted[mid];
  }

  double _calculateConfidence(List<int> intervals, int count, double avgAmount, List<double> amounts) {
    // Regularity score (0-1): how close intervals are to 30 days
    final regularityScores = intervals.map((interval) {
      final diff = (interval - _expectedIntervalDays).abs();
      return 1.0 - (diff / _expectedIntervalDays).clamp(0.0, 1.0);
    }).toList();
    final avgRegularity = regularityScores.reduce((a, b) => a + b) / regularityScores.length;

    // Count score (0-1): more occurrences = higher confidence, cap at 10
    final countScore = (count / 10).clamp(0.0, 1.0);

    // Amount consistency score (0-1)
    final amountDiffs = amounts.map((amt) => (amt - avgAmount).abs() / avgAmount).toList();
    final avgAmountDiff = amountDiffs.reduce((a, b) => a + b) / amountDiffs.length;
    final amountConsistency = 1.0 - (avgAmountDiff / _amountTolerance).clamp(0.0, 1.0);

    // Weighted combination
    return (avgRegularity * 0.5 + countScore * 0.3 + amountConsistency * 0.2).clamp(0.0, 1.0);
  }

  int? _getMostCommonCategoryId(List<TransactionModel> txs) {
    final categoryCounts = <int, int>{};
    for (final tx in txs) {
      if (tx.categoryId != null) {
        categoryCounts[tx.categoryId!] = (categoryCounts[tx.categoryId!] ?? 0) + 1;
      }
    }
    if (categoryCounts.isEmpty) return null;
    return categoryCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}