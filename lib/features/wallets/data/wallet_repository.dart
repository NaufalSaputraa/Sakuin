import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/result.dart';
import '../domain/wallet_model.dart';
import '../domain/wallet_repository_interface.dart';

class WalletRepository implements WalletRepositoryInterface {
  final AppDatabase _db;

  WalletRepository(this._db);

  WalletModel _toDomain(WalletEntry entry) {
    return WalletModel(
      id: entry.id,
      name: entry.name,
      walletType: entry.walletType,
      parentId: entry.parentId,
      provider: entry.provider,
      balance: entry.balance,
      currency: entry.currency,
      icon: entry.icon,
      color: entry.color,
      isActive: entry.isActive,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  @override
  Stream<List<WalletModel>> watchAll() {
    return _db.walletDao.watchAll().map((list) => list.map(_toDomain).toList());
  }

  @override
  Stream<double> watchTotalBalance() {
    return _db.walletDao.watchTotalBalance();
  }

  @override
  Future<Result<List<WalletModel>, AppError>> getAll() async {
    try {
      final list = await _db.walletDao.getAll();
      return Success(list.map(_toDomain).toList());
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  @override
  Future<Result<WalletModel, AppError>> getById(int id) async {
    try {
      final item = await _db.walletDao.getById(id);
      if (item == null) {
        return Failure(AppError.notFound('Wallet not found'));
      }
      return Success(_toDomain(item));
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  @override
  Stream<List<WalletModel>> watchSubWallets(int parentId) {
    return _db.walletDao
        .watchSubWallets(parentId)
        .map((list) => list.map(_toDomain).toList());
  }

  @override
  Future<Result<int, AppError>> createWallet({
    required String name,
    required String walletType,
    int? parentId,
    String? provider,
    double initialBalance = 0.0,
    String? icon,
    String? color,
    String currency = 'IDR',
  }) async {
    try {
      final id = await _db.walletDao.insertWallet(
        WalletsCompanion.insert(
          name: name,
          walletType: walletType,
          parentId: Value(parentId),
          provider: Value(provider),
          balance: Value(initialBalance),
          currency: Value(currency),
          icon: Value(icon),
          color: Value(color),
        ),
      );
      return Success(id);
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  @override
  Future<Result<bool, AppError>> updateWallet(WalletModel wallet) async {
    try {
      final entry = WalletEntry(
        id: wallet.id,
        name: wallet.name,
        walletType: wallet.walletType,
        parentId: wallet.parentId,
        provider: wallet.provider,
        balance: wallet.balance,
        currency: wallet.currency,
        icon: wallet.icon,
        color: wallet.color,
        isActive: wallet.isActive,
        createdAt: wallet.createdAt,
        updatedAt: DateTime.now(),
      );
      final updated = await _db.walletDao.updateWallet(entry);
      return Success(updated);
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }
}
