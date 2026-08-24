import '../../../core/utils/result.dart';
import 'wallet_model.dart';

abstract class WalletRepositoryInterface {
  Stream<List<WalletModel>> watchAll();
  Stream<double> watchTotalBalance();
  Future<Result<List<WalletModel>, AppError>> getAll();
  Future<Result<WalletModel, AppError>> getById(int id);
  Stream<List<WalletModel>> watchSubWallets(int parentId);
  Future<Result<int, AppError>> createWallet({
    required String name,
    required String walletType,
    int? parentId,
    String? provider,
    double initialBalance = 0.0,
    String? icon,
    String? color,
    String currency = 'IDR',
  });
  Future<Result<bool, AppError>> updateWallet(WalletModel wallet);
}
