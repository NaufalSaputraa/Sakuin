import 'package:drift/drift.dart';

@DataClassName('WalletEntry')
class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get walletType => text()(); // 'physical' | 'digital'
  IntColumn get parentId => integer().nullable().references(Wallets, #id)();
  TextColumn get provider => text().nullable()(); // 'gopay', 'ovo', 'dana', 'shopeepay', 'bank'
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('CategoryEntry')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get name => text()();
  TextColumn get nameId => text().nullable()();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  IntColumn get parentId => integer().nullable().references(Categories, #id)();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isIncome => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('TransactionEntry')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get walletId => integer().references(Wallets, #id)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  RealColumn get amount => real()();
  TextColumn get transactionType => text()(); // 'income' | 'expense' | 'transfer'
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get merchant => text().nullable()();
  TextColumn get sourceInput => text().withDefault(const Constant('manual'))(); // 'manual' | 'text_parse' | 'ocr' | 'voice' | 'ai_chat'
  TextColumn get rawInput => text().nullable()();
  IntColumn get transferToWalletId => integer().nullable().references(Wallets, #id)();
  // Multi-currency: transaction currency (defaults to IDR) + snapshot of equivalent value in IDR.
  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  RealColumn get amountBase => real().withDefault(const Constant(0.0))(); // equivalent amount in IDR
  DateTimeColumn get transactionDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Offline currency exchange rates relative to IDR (base currency).
@DataClassName('CurrencyRatesData')
class CurrencyRates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()(); // 'USD', 'SGD', 'EUR', 'JPY', 'MYR', 'IDR'
  TextColumn get name => text()(); // 'US Dollar'
  RealColumn get rateToIdr => real()(); // 1 unit of currency = rateToIdr IDR
  BoolColumn get isBase => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('BudgetEntry')
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get budgetType => text()(); // 'limit' | 'target' | 'expected'
  RealColumn get amount => real()();
  TextColumn get period => text().withDefault(const Constant('monthly'))(); // 'daily' | 'weekly' | 'monthly' | 'yearly'
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  IntColumn get walletId => integer().nullable().references(Wallets, #id)();
  DateTimeColumn get startDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ChatMessageEntry')
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  BoolColumn get isUser => boolean()();
  TextColumn get metadata => text().nullable()(); // JSON string for action transactions
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('SmartRuleEntry')
class SmartRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get conditions => text()(); // JSON string
  TextColumn get actionType => text()(); // 'categorize' | 'tag' | 'wallet'
  TextColumn get actionValue => text()(); // JSON string
  IntColumn get priority => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('SubscriptionEntry')
class Subscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get merchant => text()();
  TextColumn get normalizedKey => text()();
  RealColumn get amount => real()();
  TextColumn get period => text().withDefault(const Constant('monthly'))();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  DateTimeColumn get firstSeen => dateTime()();
  DateTimeColumn get lastSeen => dateTime()();
  IntColumn get occurrenceCount => integer().withDefault(const Constant(0))();
  RealColumn get confidence => real().withDefault(const Constant(0.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isConfirmed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
