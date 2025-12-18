// lib/features/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String _modelName = "Gymini Coach";

  @override
  void initState() {
    super.initState();
    _loadActiveModel();
  }

  Future<void> _loadActiveModel() async {
    final prefs = await SharedPreferences.getInstance();
    String provider = prefs.getString('active_ai_provider') ?? 'gemini';

    String display = "Gymini";
    if (provider == 'gemini')
      display = "Gymini (Gemini)";
    else if (provider == 'openai')
      display = "Gymini (ChatGPT)";
    else if (provider == 'deepseek') display = "Gymini (DeepSeek)";

    if (mounted) {
      setState(() {
        _modelName = display;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(_modelName)),
      body: DashChat(
        currentUser: ChatUser(id: '1'),
        onSend: (ChatMessage m) {
          chatProvider.sendMessage(m);
        },
        messages: chatProvider.messages,

        // --- FIX IS HERE ---
        // We use '_modelName' instead of the hardcoded string 'Coach'
        typingUsers: chatProvider.isTyping
            ? [ChatUser(id: '2', firstName: _modelName)]
            : [],

        // Custom Render Logic (Keep exactly as before)
        messageOptions: MessageOptions(
            currentUserContainerColor: const Color.fromARGB(255, 116, 164, 248),
            containerColor: Colors.grey[200]!,
            messageTextBuilder: (message, previous, next) {
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
