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
  final Color _themeColor = Colors.deepPurple;

  @override
  void initState() {
    super.initState();
    _loadActiveModel();
  }

  Future<void> _loadActiveModel() async {
    final prefs = await SharedPreferences.getInstance();
    String provider = prefs.getString('active_ai_provider') ?? 'gemini';

    String display = "Gymini";
    if (provider == 'gemini') {
      display = "Gymini (Gemini)";
    } else if (provider == 'openai') {
      display = "Gymini (ChatGPT)";
    } else if (provider == 'deepseek') {
      display = "Gymini (DeepSeek)";
    } else if (provider == 'chatanywhere') {
      display = "Gymini (ChatAnywhere)";
    }

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
        typingUsers: chatProvider.isTyping
            ? [ChatUser(id: '2', firstName: _modelName)]
            : [],
        messageOptions: MessageOptions(
          currentUserContainerColor: _themeColor,
          containerColor: Colors.grey[200]!,
          messageTextBuilder: (message, previous, next) {
            String actionType =
                message.customProperties?['action_type'] ?? 'general_chat';
            bool isUser = message.user.id == '1';

            Widget textContent = Text(message.text,
                style: TextStyle(color: isUser ? Colors.white : Colors.black));

            if (isUser) return textContent;

            switch (actionType) {
              // --- MODE 1: ANALYSIS ---
              case 'analysis':
                String insight =
                    message.customProperties?['analysis_insight'] ?? '';
                String advice =
                    message.customProperties?['actionable_advice'] ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textContent,
                    if (insight.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildInfoBox(color: Colors.deepPurple, text: insight),
                    ],
                    if (advice.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoBox(color: Colors.green, text: advice),
                    ],
                  ],
                );

              // --- MODE 2: ROUTINE SUGGESTION ---
              case 'routine_suggestion':
                final routineList =
                    message.customProperties?['suggested_routine'];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textContent,
                    if (routineList != null && routineList is List) ...[
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: _themeColor.withOpacity(0.1),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8)),
                              ),
                              child: Text(
                                "Suggested Workout", // Removed emoji
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _themeColor),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            ...routineList.map((ex) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color: Colors.grey.shade200))),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                        child: Text(
                                            ex['exercise_name'] ?? 'Exercise',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    Text(
                                        "${ex['sets']}x${ex['reps']} @ ${ex['weight_kg']}kg",
                                        style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 13)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      )
                    ]
                  ],
                );

              // --- MODE 3: EDUCATION ---
              case 'education':
                final guide = message.customProperties?['technique_guide'];
                List cues = [];
                List mistakes = [];
                if (guide != null && guide is Map) {
                  cues = guide['cues'] ?? [];
                  mistakes = guide['mistakes'] ?? [];
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textContent,
                    const SizedBox(height: 10),
                    if (cues.isNotEmpty) ...[
                      const Text("Technique Cues", // Removed checkmark
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.green)),
                      ...cues.map((c) => Padding(
                            padding: const EdgeInsets.only(
                                left: 0,
                                top: 4), // Removed indentation for icon
                            child: Text("- $c", // Added dash bullet
                                style: const TextStyle(fontSize: 13)),
                          )),
                      const SizedBox(height: 10),
                    ],
                    if (mistakes.isNotEmpty) ...[
                      const Text("Common Mistakes", // Removed cross
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.red)),
                      ...mistakes.map((m) => Padding(
                            padding: const EdgeInsets.only(left: 0, top: 4),
                            child: Text("- $m", // Added dash bullet
                                style: const TextStyle(fontSize: 13)),
                          )),
                    ]
                  ],
                );

              // --- MODE 4: ADJUSTMENT ---
              case 'adjustment':
                final sub = message.customProperties?['substitution'];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textContent,
                    if (sub != null && sub is Map) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Exercise Modification",
                                style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold)),
                            const Divider(height: 15),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  const TextSpan(text: "Instead of: "),
                                  TextSpan(
                                      text: "${sub['original_exercise']}\n",
                                      style: const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey)),
                                  const TextSpan(text: "Try: "),
                                  TextSpan(
                                      text: sub['replacement'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Reason: ${sub['reasoning']}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                //fontStyle: FontStyle.italic
                              ),
                            )
                          ],
                        ),
                      )
                    ]
                  ],
                );

              default:
                return textContent;
            }
          },
        ),
      ),
    );
  }

  // Helper widget - Removed Icon Parameter
  Widget _buildInfoBox({required Color color, required String text}) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity, // Ensure full width text
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color.withOpacity(0.9), fontWeight: FontWeight.bold)),
    );
  }
}
