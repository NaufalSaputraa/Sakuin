import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../domain/chat_message_model.dart';
import '../domain/chat_repository_interface.dart';

class ChatRepository implements ChatRepositoryInterface {
  final AppDatabase _db;

  ChatRepository(this._db);

  ChatMessageModel _toDomain(ChatMessageEntry entry) {
    return ChatMessageModel(
      id: entry.id,
      content: entry.content,
      isUser: entry.isUser,
      metadata: entry.metadata,
      timestamp: entry.timestamp,
    );
  }

  @override
  Stream<List<ChatMessageModel>> watchMessages() {
    return _db.chatDao.watchAll().map((list) => list.map(_toDomain).toList());
  }

  @override
  Future<List<ChatMessageModel>> getMessages() async {
    final list = await _db.chatDao.getAll();
    return list.map(_toDomain).toList();
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
