import '../../domain/entities/chatMessage.dart';
import '../../domain/repositories/chatRepository.dart';
import '../dataSources/openAIRemoteDataSource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final OpenAIRemoteDataSource remoteDataSource;

  ChatRepositoryImpl(this.remoteDataSource);

  @override
  Future<ChatMessage> sendMessage(String message) async {
    final reply = await remoteDataSource.sendMessage(message);

    return ChatMessage(
      text: reply,
      isUser: false,
    );
  }
}