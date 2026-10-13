import 'package:flutter/material.dart';

import '../../domain/entities/chatMessage.dart';
import '../../domain/useCases/sendMessage.dart';

class ChatProvider extends ChangeNotifier {
  final SendMessage sendMessageUseCase;

  ChatProvider(this.sendMessageUseCase);

  final List<ChatMessage> messages = [
    ChatMessage(text: '', isUser: false, isGreeting: true),
  ];
  bool isLoading = false;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    messages.add(ChatMessage(text: text, isUser: true, isGreeting: false));
    isLoading = true;
    notifyListeners();

    try {
      final botMessage = await sendMessageUseCase(text);
      botMessage.animate = true;
      messages.add(botMessage);
    } catch (e) {
      debugPrint('CHAT ERROR: $e');

      messages.add(ChatMessage(
        text: 'Error: $e',
        isUser: false,
        isGreeting: false
      ));
    }

    isLoading = false;
    notifyListeners();
  }
}