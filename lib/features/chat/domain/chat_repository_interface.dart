import '../../../core/database/app_database.dart';

abstract class ChatRepositoryInterface {
  Stream<List<ChatMessageEntry>> watchMessages();
  Future<List<ChatMessageEntry>> getMessages();
  Future<int> addMessage({required String content, required bool isUser, String? metadata});
  Future<int> deleteMessage(int id);
  Future<int> clearHistory();
}
