// lib/features/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get the manager
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Gymini Coach')),
      body: DashChat(
        currentUser: ChatUser(id: '1'),
        onSend: (ChatMessage m) {
          chatProvider.sendMessage(m);
        },
        messages: chatProvider.messages,
        typingUsers: chatProvider.isTyping
            ? [ChatUser(id: '2', firstName: 'Gymini')]
            : [],

        // 2. Custom Render Logic
        messageOptions: MessageOptions(
            currentUserContainerColor: const Color.fromARGB(255, 116, 164, 248),
            containerColor: Colors.grey[200]!,
            messageTextBuilder: (message, previous, next) {
              // Check if this is a "Special" Analysis message
              bool isAnalysis =
                  message.customProperties?['action_type'] == 'analysis';

              if (isAnalysis) {
                String insight =
                    message.customProperties?['analysis_insight'] ?? '';
                String advice =
                    message.customProperties?['actionable_advice'] ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message.text,
                        style: TextStyle(
                            color: message.user.id == '1'
                                ? Colors.white
                                : Colors.black)),
                    const SizedBox(height: 10),

                    // Render the Insights Card
                    if (insight.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(insight,
                                    style: TextStyle(
                                        color: Colors.red[900],
                                        fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),

                    // Render the Advice Card
                    if (advice.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(advice,
                                    style: TextStyle(
                                        color: Colors.green[900],
                                        fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                  ],
                );
              }

              // Default View
              return Text(message.text,
                  style: TextStyle(
                      color: message.user.id == '1'
                          ? Colors.white
                          : Colors.black));
            }),
      ),
    );
  }
}
