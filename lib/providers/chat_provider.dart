import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import '../services/ai_service.dart';
import '../models/gymini_response.dart';

class ChatProvider extends ChangeNotifier {
  final AIService _aiService = AIService();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;

  final ChatUser _user = ChatUser(id: '1', firstName: 'Athlete');
  final ChatUser _gymini = ChatUser(id: '2', firstName: 'Gymini Coach');

  ChatProvider() {
    _messages.add(
      ChatMessage(
        text: "I'm connected to your logs. Ask me about your progress!",
        user: _gymini,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> sendMessage(ChatMessage userMessage) async {
    _messages.insert(0, userMessage);
    _isTyping = true;
    notifyListeners();

    try {
      GyminiResponse response = await _aiService.sendMessage(userMessage.text);

      // Store the fancy data in 'customProperties' so the UI can find it later
      Map<String, dynamic> properties = {
        'action_type': response.actionType,
        'analysis_insight': response.analysisInsight,
        'actionable_advice': response.actionableAdvice,
      };

      final aiMessage = ChatMessage(
        text: response.responseText,
        user: _gymini,
        createdAt: DateTime.now(),
        customProperties: properties,
      );

      _messages.insert(0, aiMessage);
    } catch (e) {
      _messages.insert(
          0,
          ChatMessage(
            text: "Error: $e",
            user: _gymini,
            createdAt: DateTime.now(),
          ));
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }
}
