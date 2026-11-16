import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wellmate/core/theme/colors.dart';
import 'package:wellmate/core/theme/textStyles.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/chatProvider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage(ChatProvider provider) {
    if (_controller.text.trim().isEmpty) return;

    provider.sendMessage(_controller.text.trim());

    _controller.clear();

    Future.delayed(
      const Duration(milliseconds: 300),
          () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final loc =
    AppLocalizations.of(context)!;
    final locale =
    Localizations.localeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          loc.chatBotTitle,
          style: AppTextStyles.semiBold(locale).copyWith(
          fontSize: 20,
        ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              itemCount: provider.messages.length,
              itemBuilder: (context, index) {
                final message = provider.messages[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: message.isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!message.isUser)
                        const CircleAvatar(
                          radius: 16,
                          child: Icon(Icons.smart_toy, size: 18),
                        ),

                      if (!message.isUser)
                        const SizedBox(width: 8),

                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: message.isUser
                                ? AppColors.appGreen
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            message.text,
                            style: AppTextStyles.introDesc(locale).copyWith(
                              color: message.isUser
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 15,
                              height: 1.4
                            )
                          ),
                        ),
                      ),

                      if (message.isUser)
                        const SizedBox(width: 8),

                      if (message.isUser)
                        const CircleAvatar(
                          radius: 16,
                          child: Icon(Icons.person, size: 18),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          if (provider.isLoading)
            const Padding(
              padding: EdgeInsets.only(
                left: 20,
                bottom: 10,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.smart_toy, size: 18),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ),
            ),

          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                12,
              ),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _controller,
                        textCapitalization:
                        TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: loc.chatBotHint,
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) =>
                            _sendMessage(provider),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: IconButton(
                      onPressed: () => _sendMessage(provider),
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}