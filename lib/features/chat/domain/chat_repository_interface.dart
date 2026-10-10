import 'chat_message_model.dart';

abstract class ChatRepositoryInterface {
  Stream<List<ChatMessageModel>> watchMessages();
  Future<List<ChatMessageModel>> getMessages();
  Future<int> addMessage({required String content, required bool isUser, String? metadata});
  Future<int> deleteMessage(int id);
  Future<int> clearHistory();
}
