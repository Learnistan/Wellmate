class ChatMessage {
  final String text;
  final bool isUser;
  final bool isGreeting;
  bool animate;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.isGreeting,
    this.animate = false,
  });
}