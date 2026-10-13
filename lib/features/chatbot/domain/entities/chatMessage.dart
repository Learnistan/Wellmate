class ChatMessage {
  final String text;
  final bool isUser;
  final bool isGreeting;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.isGreeting
  });
}