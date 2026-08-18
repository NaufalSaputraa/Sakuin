import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'chat_dao.g.dart';

@DriftAccessor(tables: [ChatMessages])
class ChatDao extends DatabaseAccessor<AppDatabase> with _$ChatDaoMixin {
  ChatDao(super.db);

  Stream<List<ChatMessageEntry>> watchAll() {
    return (select(chatMessages)..orderBy([(t) => OrderingTerm(expression: t.timestamp)])).watch();
  }

  Future<List<ChatMessageEntry>> getAll() {
    return (select(chatMessages)..orderBy([(t) => OrderingTerm(expression: t.timestamp)])).get();
  }

  Future<int> insertMessage(ChatMessagesCompanion companion) {
    return into(chatMessages).insert(companion);
  }

  Future<int> deleteMessage(int id) {
    return (delete(chatMessages)..where((t) => t.id.equals(id))).go();
  }

  Future<int> clearAll() {
    return delete(chatMessages).go();
  }
}
