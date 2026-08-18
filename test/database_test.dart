import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:sakuin_app/core/database/app_database.dart';
import 'package:sakuin_app/features/wallets/data/wallet_repository.dart';
import 'package:sakuin_app/features/transactions/data/transaction_repository.dart';
import 'package:sakuin_app/features/transactions/domain/transaction_model.dart';
import 'package:sakuin_app/features/categories/data/category_repository.dart';
import 'package:sakuin_app/features/chat/data/chat_repository.dart';

void main() {
  late AppDatabase db;
  late WalletRepository walletRepo;
  late TransactionRepository txRepo;
  late CategoryRepository categoryRepo;
  late ChatRepository chatRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    walletRepo = WalletRepository(db);
    txRepo = TransactionRepository(db);
    categoryRepo = CategoryRepository(db);
    chatRepo = ChatRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift In-Memory Database & Repository Integration Tests', () {
    test('creates wallet and retrieves by ID', () async {
      final res = await walletRepo.createWallet(
        name: 'Dompet Tes',
        walletType: 'physical',
        initialBalance: 100000.0,
      );

      expect(res.isSuccess, isTrue);
      final walletId = res.valueOrNull!;

      final getRes = await walletRepo.getById(walletId);
      expect(getRes.isSuccess, isTrue);
      final wallet = getRes.valueOrNull!;
      expect(wallet.name, 'Dompet Tes');
      expect(wallet.balance, 100000.0);
    });

    test('creating expense transaction deducts wallet balance atomically', () async {
      final walletRes = await walletRepo.createWallet(
        name: 'GoPay Tes',
        walletType: 'digital',
        provider: 'gopay',
        initialBalance: 50000.0,
      );

      final walletId = walletRes.valueOrNull!;

      final txRes = await txRepo.createTransaction(
        walletId: walletId,
        amount: 25000.0,
        transactionType: TransactionType.expense,
        title: 'Kopi Kenangan',
      );

      expect(txRes.isSuccess, isTrue);

      final updatedWallet = (await walletRepo.getById(walletId)).valueOrNull!;
      expect(updatedWallet.balance, 25000.0);
    });

    test('creating income transaction adds to wallet balance', () async {
      final walletRes = await walletRepo.createWallet(
        name: 'Rekening Tes',
        walletType: 'digital',
        initialBalance: 1000000.0,
      );

      final walletId = walletRes.valueOrNull!;

      final txRes = await txRepo.createTransaction(
        walletId: walletId,
        amount: 500000.0,
        transactionType: TransactionType.income,
        title: 'Gaji Freelance',
      );

      expect(txRes.isSuccess, isTrue);

      final updatedWallet = (await walletRepo.getById(walletId)).valueOrNull!;
      expect(updatedWallet.balance, 1500000.0);
    });

    test('deleting transaction restores wallet balance', () async {
      final walletRes = await walletRepo.createWallet(
        name: 'Cash',
        walletType: 'physical',
        initialBalance: 100000.0,
      );

      final walletId = walletRes.valueOrNull!;

      final txRes = await txRepo.createTransaction(
        walletId: walletId,
        amount: 30000.0,
        transactionType: TransactionType.expense,
        title: 'Makan Siang',
      );

      final txId = txRes.valueOrNull!;
      expect((await walletRepo.getById(walletId)).valueOrNull!.balance, 70000.0);

      final deleteRes = await txRepo.deleteTransaction(txId);
      expect(deleteRes.isSuccess, isTrue);

      expect((await walletRepo.getById(walletId)).valueOrNull!.balance, 100000.0);
    });

    test('Category CRUD operations work correctly', () async {
      // Create Category
      final createRes = await categoryRepo.createCategory(
        key: 'gaming',
        name: 'Gaming',
        nameId: 'Main Game',
        icon: '🎮',
        color: '#9B59B6',
        isIncome: false,
      );

      expect(createRes.isSuccess, isTrue);
      final catId = createRes.valueOrNull!;

      // Retrieve by ID
      final getRes = await categoryRepo.getById(catId);
      expect(getRes.isSuccess, isTrue);
      expect(getRes.valueOrNull!.name, 'Gaming');
      expect(getRes.valueOrNull!.icon, '🎮');

      // Delete Category
      final delRes = await categoryRepo.deleteCategory(catId);
      expect(delRes.isSuccess, isTrue);

      // Verify Deleted
      final getAfterDel = await categoryRepo.getById(catId);
      expect(getAfterDel.isFailure, isTrue);
    });

    test('Chat history persistent storage and clear work correctly', () async {
      // Add user message
      final msg1 = await chatRepo.addMessage(content: 'Berapa saldoku?', isUser: true);
      expect(msg1, greaterThan(0));

      // Add AI reply
      final msg2 = await chatRepo.addMessage(content: 'Total saldomu Rp 500.000', isUser: false);
      expect(msg2, greaterThan(0));

      // Check messages count
      final list = await chatRepo.getMessages();
      expect(list.length, greaterThanOrEqualTo(2));

      // Delete single message
      await chatRepo.deleteMessage(msg1);
      final listAfterDel = await chatRepo.getMessages();
      expect(listAfterDel.any((m) => m.id == msg1), isFalse);

      // Clear all
      await chatRepo.clearHistory();
      final listCleared = await chatRepo.getMessages();
      expect(listCleared.isEmpty, isTrue);
    });
  });
}
