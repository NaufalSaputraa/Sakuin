import '../../../core/database/app_database.dart';
import '../../../core/utils/result.dart';
import '../domain/subscription_model.dart';
import '../domain/subscription_repository_interface.dart';

class SubscriptionRepository implements SubscriptionRepositoryInterface {
  final AppDatabase _db;

  SubscriptionRepository(this._db);

  SubscriptionModel _toDomain(SubscriptionEntry entry) {
    return SubscriptionModel(
      id: entry.id,
      merchant: entry.merchant,
      normalizedKey: entry.normalizedKey,
      amount: entry.amount,
      period: entry.period,
      categoryId: entry.categoryId,
      firstSeen: entry.firstSeen,
      lastSeen: entry.lastSeen,
      occurrenceCount: entry.occurrenceCount,
      confidence: entry.confidence,
      isActive: entry.isActive,
      isConfirmed: entry.isConfirmed,
      createdAt: entry.createdAt,
    );
  }

  @override
  Stream<List<SubscriptionModel>> watchSubscriptions() {
    return _db.subscriptionDao.watchAll().map((list) => list.map(_toDomain).toList());
  }

  @override
  Stream<List<SubscriptionModel>> watchActiveSubscriptions() {
    return _db.subscriptionDao.watchActive().map((list) => list.map(_toDomain).toList());
  }

  @override
  Future<Result<SubscriptionModel, AppError>> getById(int id) async {
    try {
      final item = await _db.subscriptionDao.getById(id);
      if (item == null) {
        return Failure(AppError.notFound('Subscription not found'));
      }
      return Success(_toDomain(item));
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  @override
  Future<Result<int, AppError>> upsert(SubscriptionModel subscription) async {
    try {
      final id = await _db.subscriptionDao.upsertByKey(
        normalizedKey: subscription.normalizedKey,
        merchant: subscription.merchant,
        amount: subscription.amount,
        period: subscription.period,
        categoryId: subscription.categoryId,
        firstSeen: subscription.firstSeen,
        lastSeen: subscription.lastSeen,
        occurrenceCount: subscription.occurrenceCount,
        confidence: subscription.confidence,
      );
      return Success(id);
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  @override
  Future<Result<bool, AppError>> setConfirmed(int id, bool confirmed) async {
    try {
      final updated = await _db.subscriptionDao.setConfirmed(id, confirmed);
      return Success(updated > 0);
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  @override
  Future<Result<bool, AppError>> setActive(int id, bool active) async {
    try {
      final updated = await _db.subscriptionDao.setActive(id, active);
      return Success(updated > 0);
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  @override
  Future<Result<bool, AppError>> delete(int id) async {
    try {
      final deleted = await _db.subscriptionDao.deleteSubscription(id);
      return Success(deleted > 0);
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }
}