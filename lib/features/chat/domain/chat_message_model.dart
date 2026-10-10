class ChatMessageModel {
  final int id;
  final String content;
  final bool isUser;
  final String? metadata;
  final DateTime timestamp;

  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.isUser,
    this.metadata,
    required this.timestamp,
  });
}
