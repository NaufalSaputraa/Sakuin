import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../services/subscription_detector_service.dart';
import '../data/subscription_repository.dart';
import '../domain/subscription_model.dart';
import '../domain/subscription_repository_interface.dart';
import '../../transactions/domain/transaction_model.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return SubscriptionRepository(db);
});

final subscriptionDetectorServiceProvider = Provider<SubscriptionDetectorService>((ref) {
  return SubscriptionDetectorService();
});

final watchSubscriptionsProvider = StreamProvider.autoDispose<List<SubscriptionModel>>((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.watchSubscriptions();
});

final watchActiveSubscriptionsProvider = StreamProvider.autoDispose<List<SubscriptionModel>>((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.watchActiveSubscriptions();
});

final detectedSubscriptionsProvider = FutureProvider.autoDispose<List<DetectedSubscription>>((ref) async {
  final transactionDao = ref.read(databaseProvider).transactionDao;
  final detector = ref.read(subscriptionDetectorServiceProvider);

  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 90));
  final entries = await transactionDao.getByDateRange(start, now);
  final transactions = entries.map(TransactionModel.fromEntry).toList();

  return detector.detect(transactions);
});

class SubscriptionsNotifier extends AsyncNotifier<List<SubscriptionModel>> {
  @override
  Future<List<SubscriptionModel>> build() async {
    final repo = ref.read(subscriptionRepositoryProvider);
    final result = await repo.watchSubscriptions().first;
    return result;
  }

  Future<void> detectAndSave() async {
    state = const AsyncValue.loading();
    try {
      final transactionDao = ref.read(databaseProvider).transactionDao;
      final detector = ref.read(subscriptionDetectorServiceProvider);
      final repo = ref.read(subscriptionRepositoryProvider);

      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 90));
      final entries = await transactionDao.getByDateRange(start, now);
      final transactions = entries.map(TransactionModel.fromEntry).toList();

      final detected = detector.detect(transactions);

      for (final sub in detected) {
        final model = SubscriptionModel(
          id: 0, // Will be assigned by DB
          merchant: sub.merchant,
          normalizedKey: sub.normalizedKey,
          amount: sub.amount,
          period: sub.period,
          categoryId: sub.categoryId,
          firstSeen: sub.firstSeen,
          lastSeen: sub.lastSeen,
          occurrenceCount: sub.occurrenceCount,
          confidence: sub.confidence,
          isActive: true,
          isConfirmed: false,
          createdAt: DateTime.now(),
        );
        await repo.upsert(model);
      }

      // Refresh the list
      final result = await repo.watchSubscriptions().first;
      state = AsyncValue.data(result);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> confirmSubscription(int id) async {
    final repo = ref.read(subscriptionRepositoryProvider);
    final result = await repo.setConfirmed(id, true);
    if (result.isSuccess) {
      final current = state.value ?? [];
      state = AsyncValue.data(
        current.map((s) => s.id == id ? s.copyWith(isConfirmed: true) : s).toList(),
      );
    } else {
      throw result.errorOrNull!;
    }
  }

  Future<void> ignoreSubscription(int id) async {
    final repo = ref.read(subscriptionRepositoryProvider);
    final result = await repo.setActive(id, false);
    if (result.isSuccess) {
      final current = state.value ?? [];
      state = AsyncValue.data(
        current.map((s) => s.id == id ? s.copyWith(isActive: false) : s).toList(),
      );
    } else {
      throw result.errorOrNull!;
    }
  }

  Future<void> deleteSubscription(int id) async {
    final repo = ref.read(subscriptionRepositoryProvider);
    final result = await repo.delete(id);
    if (result.isSuccess) {
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((s) => s.id != id).toList());
    } else {
      throw result.errorOrNull!;
    }
  }
}

final subscriptionsNotifierProvider = AsyncNotifierProvider<SubscriptionsNotifier, List<SubscriptionModel>>(
  SubscriptionsNotifier.new,
);