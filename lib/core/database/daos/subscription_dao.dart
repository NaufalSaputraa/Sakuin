import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'subscription_dao.g.dart';

@DriftAccessor(tables: [Subscriptions])
class SubscriptionDao extends DatabaseAccessor<AppDatabase> with _$SubscriptionDaoMixin {
  SubscriptionDao(super.db);

  Stream<List<SubscriptionEntry>> watchAll() {
    return (select(subscriptions)
          ..orderBy([(s) => OrderingTerm(expression: s.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Stream<List<SubscriptionEntry>> watchActive() {
    return (select(subscriptions)
          ..where((s) => s.isActive.equals(true))
          ..orderBy([(s) => OrderingTerm(expression: s.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<SubscriptionEntry?> getById(int id) {
    return (select(subscriptions)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertSubscription(SubscriptionsCompanion companion) {
    return into(subscriptions).insert(companion);
  }

  Future<bool> updateSubscription(SubscriptionEntry entry) {
    return update(subscriptions).replace(entry);
  }

  Future<int> upsertByKey({
    required String normalizedKey,
    required String merchant,
    required double amount,
    required String period,
    int? categoryId,
    required DateTime firstSeen,
    required DateTime lastSeen,
    required int occurrenceCount,
    required double confidence,
  }) async {
    final existing = await (select(subscriptions)
          ..where((s) => s.normalizedKey.equals(normalizedKey)))
        .getSingleOrNull();

    if (existing != null) {
      await update(subscriptions).replace(
        SubscriptionEntry(
          id: existing.id,
          merchant: merchant,
          normalizedKey: normalizedKey,
          amount: amount,
          period: period,
          categoryId: categoryId,
          firstSeen: firstSeen,
          lastSeen: lastSeen,
          occurrenceCount: occurrenceCount,
          confidence: confidence,
          isActive: existing.isActive,
          isConfirmed: existing.isConfirmed,
          createdAt: existing.createdAt,
        ),
      );
      return existing.id;
    } else {
      return await into(subscriptions).insert(
        SubscriptionsCompanion.insert(
          merchant: merchant,
          normalizedKey: normalizedKey,
          amount: amount,
          period: Value(period),
          categoryId: Value(categoryId),
          firstSeen: firstSeen,
          lastSeen: lastSeen,
          occurrenceCount: Value(occurrenceCount),
          confidence: Value(confidence),
        ),
      );
    }
  }

  Future<int> deleteSubscription(int id) {
    return (delete(subscriptions)..where((s) => s.id.equals(id))).go();
  }

  Future<int> setConfirmed(int id, bool confirmed) {
    return (update(subscriptions)..where((s) => s.id.equals(id)))
        .write(SubscriptionsCompanion(isConfirmed: Value(confirmed)));
  }

  Future<int> setActive(int id, bool active) {
    return (update(subscriptions)..where((s) => s.id.equals(id)))
        .write(SubscriptionsCompanion(isActive: Value(active)));
  }
}