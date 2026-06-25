import '../entities/chatMessage.dart';
import '../repositories/chatRepository.dart';

class SendMessage {
  final ChatRepository repository;

  SendMessage(this.repository);

  Future<ChatMessage> call(String message) {
    return repository.sendMessage(message);
  }
}