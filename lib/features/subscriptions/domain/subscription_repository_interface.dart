import '../../../core/utils/result.dart';
import 'subscription_model.dart';

abstract class SubscriptionRepositoryInterface {
  Stream<List<SubscriptionModel>> watchSubscriptions();
  Stream<List<SubscriptionModel>> watchActiveSubscriptions();
  Future<Result<SubscriptionModel, AppError>> getById(int id);
  Future<Result<int, AppError>> upsert(SubscriptionModel subscription);
  Future<Result<bool, AppError>> setConfirmed(int id, bool confirmed);
  Future<Result<bool, AppError>> setActive(int id, bool active);
  Future<Result<bool, AppError>> delete(int id);
}