import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../data/chat_repository.dart';
import '../domain/chat_message_model.dart';
import '../domain/chat_repository_interface.dart';

final chatRepositoryProvider = Provider<ChatRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return ChatRepository(db);
});

final chatMessagesStreamProvider = StreamProvider.autoDispose<List<ChatMessageModel>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchMessages();
});
