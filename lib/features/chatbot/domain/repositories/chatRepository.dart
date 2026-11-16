import '../entities/chatMessage.dart';

abstract class ChatRepository {
  Future<ChatMessage> sendMessage(String message);
}