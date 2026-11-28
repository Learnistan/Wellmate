import 'package:flutter/material.dart';

import '../../../../core/utils/rateLimiter.dart';
import '../../domain/entities/chatMessage.dart';
import '../../domain/useCases/sendMessage.dart';

class ChatProvider extends ChangeNotifier {
  final SendMessage sendMessageUseCase;
  final RateLimiter _limiter = RateLimiter();

  ChatProvider(this.sendMessageUseCase);

  final List<ChatMessage> messages = [
    ChatMessage(text: '', isUser: false, isGreeting: true),
  ];

  bool isLoading = false;
  Duration? retryAfter;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || isLoading) return;

    final wait = await _limiter.tryConsume();
    if (wait != null) {
      retryAfter = wait;
      notifyListeners();
      return;
    }

    retryAfter = null;

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