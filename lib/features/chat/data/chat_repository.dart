import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../domain/chat_repository_interface.dart';

class ChatRepository implements ChatRepositoryInterface {
  final AppDatabase _db;

  ChatRepository(this._db);

  @override
  Stream<List<ChatMessageEntry>> watchMessages() {
    return _db.chatDao.watchAll();
  }

  @override
  Future<List<ChatMessageEntry>> getMessages() {
    return _db.chatDao.getAll();
  }

  @override
  Future<int> addMessage({required String content, required bool isUser, String? metadata}) {
    return _db.chatDao.insertMessage(
      ChatMessagesCompanion.insert(
        content: content,
        isUser: isUser,
        metadata: Value(metadata),
      ),
    );
  }

  @override
  Future<int> deleteMessage(int id) {
    return _db.chatDao.deleteMessage(id);
  }

  @override
  Future<int> clearHistory() {
    return _db.chatDao.clearAll();
  }
}
